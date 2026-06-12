terraform {
  required_version = ">= 1.6.0"
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = "~> 1.2.0"
    }
  }
}

provider "hyperv" {
  # Defaults to connecting locally (127.0.0.1 via WinRM). 
  # Set environment variables HYPERV_USER and HYPERV_PASSWORD if running across a network.
}

# --- Environment Variables & Helpers ---
locals {
  vm_hyperv_name = "kali-rolling"
  common_pkgs    = ["bind9-utils", "dnsutils", "git", "htop", "iptables", "net-tools", "network-manager", "tcpdump", "tmux", "vim", "wget", "curl"]

  # Helper functions mapped directly to strings
  apt_update  = "apt-get update"
  apt_upgrade = "apt-get upgrade -y"
  apt_install = "apt-get install -y ${join(" ", distinct(local.common_pkgs))}"

  shell_customizations = <<SHELL
    SHELL_ADDITIONS="alias lss='ls -alhF --group-directories-first'
alias ip='ip --color=auto'
alias grep='grep --color=auto'
"

    VIM_ADDITIONS="syntax on
set number
set hlsearch
set incsearch
set ignorecase
set smartcase
highlight Search ctermbg=yellow ctermfg=black
highlight CurSearch ctermbg=red ctermfg=white"

    configure_user_environment() {
      local user="$1"
      local home_dir="$2"
      
      # Get user's default shell
      local user_shell=$(getent passwd "$user" | cut -d: -f7)
      local rc_file="$home_dir/.bashrc"
      
      if [[ "$user_shell" =~ "zsh" ]]; then
        rc_file="$home_dir/.zshrc"
      fi

      # Write dedicated custom profile file
      local custom_rc="$home_dir/.shell_custom"
      echo "$SHELL_ADDITIONS" > "$custom_rc"
      chown "$user":"$user" "$custom_rc"

      touch "$rc_file"
      if [[ "$rc_file" == *".bashrc" ]]; then
        sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' "$rc_file"
      fi

      # Only append source link line if it doesn't exist
      local shell_source_line="source $custom_rc"
      if ! grep -Fxq "$shell_source_line" "$rc_file"; then
        echo -e "\n$shell_source_line" >> "$rc_file"
      fi
      chown "$user":"$user" "$rc_file"

      # Configure Vim for the user
      local vimrc="$home_dir/.vimrc"
      local custom_vimrc="$home_dir/.vimrc_custom"
      
      # Write dedicated custom vim file
      echo "$VIM_ADDITIONS" > "$custom_vimrc"
      chown "$user":"$user" "$custom_vimrc"

      touch "$vimrc"
      
      # Only append source link line if it doesn't exist 
      local vim_source_line="source $custom_vimrc"
      if ! grep -Fxq "$vim_source_line" "$vimrc"; then
        echo -e "\n$vim_source_line" >> "$vimrc"
      fi
      chown "$user":"$user" "$vimrc"
    }

    # Automatically deploy for both environments
    configure_user_environment "root" "/root"
  SHELL
}

# --- Storage Provisioning ---
# OpenTofu doesn't pull boxes directly from Vagrant Cloud. Point 'source' to your base Kali VHDX.
resource "hyperv_vhd" "kali_disk" {
  path        = "..\\Disks\\${local.vm_hyperv_name}.vhdx"
  # source      = "..\\BaseImages\\<name>.vhdx"
}

# --- VM Definition ---
resource "hyperv_machine_instance" "kali" {
  name                 = local.vm_hyperv_name
  generation           = 2
  processor_count      = 4
  memory_startup_bytes = 2048 * 1024 * 1024 # 2048 MB in bytes
  static_memory        = true

  # Attach your hard disk drive
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.kali_disk.path
  }

  # Hook up to your default virtual switch (replace with your exact Hyper-V switch name)
  network_adaptors {
    name        = "wan"
    switch_name = "Default Switch" 
  }

  # --- Native Boot Order Assignment ---
  # No more trigger scripts! OpenTofu provisions the proper boot order right out of the gate.
  vm_firmware {
    enable_secure_boot = "Off"
    boot_order {
      boot_type           = "HardDiskDrive"
      controller_number   = 0
      controller_location = 0
    }
  }

  # --- Integration Services Mapping ---
  integration_services = {
    "Guest Service Interface" = true
    "Heartbeat"               = true
    "Key-Value Pair Exchange" = true
    "Shutdown"                = true
    "Time Synchronization"    = true
    "VSS"                     = false
  }

  # --- Provisioning Script Integration ---
  # Runs your exact scripts inside the instance after boot up completes
  connection {
    type     = "ssh"
    user     = "root"
    password = "root"
    host     = self.network_adaptors[0].ip_addresses[0]
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "set -eux",
      local.apt_update,
      local.apt_install,
      local.shell_customizations
    ]
  }
}