# Sysadmin IaC Workspace

Opinionated modular Infrastructure as Code (IaC) and local virtualization environment utilizing **OpenTofu** and **Vagrant**. 

This repository is structured to quickly provision local development, administration, and penetration testing virtual machines (Hyper-V, VirtualBox) using centralized, decoupled system configurations.

---

## Repository Structure

The project is structured by orchestration tool, hypervisor (provider) and machine type.

```text
sysadmin/
├── LICENSE
├── README.md
├── opentofu/
│   ├── hyper-v/
│   │   ├── kali/
│   │   │   └── main.tf
│   │   └── template/
│   │       └── main.tf
│   └── proxmox/
│       └── template/
└── vagrant/
    ├── hyper-v/
    │   ├── kali/
    │   │   └── Vagrantfile
    │   └── template/
    │       └── Vagrantfile
    └── virtualbox/
        └── template/
```

---

## Prerequisites

To run these configurations locally, ensure the following are installed and enabled on your Windows host:

* **Hyper-V** (Enabled via Windows Features)
   ```ps1
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
* **Vagrant** (v2.x+) - Tested with v2.4.9
* **OpenTofu** (v1.6.0+) - Tested with v1.12.1
* **PowerShell** (For execution and WinRM connectivity)

> **Note on OpenTofu & Hyper-V:** Ensure WinRM is enabled on your host (`winrm quickconfig`) to allow OpenTofu to communicate with the local Hyper-V management layer.

---

## Getting Started

### Vagrant Environments

For Vagrant environments, with Hyper-V as the provider, you need to run it as an **Administrator**.

1. Navigate to your target machine directory:
   ```ps1
   cd vagrant/hyper-v/kali
   ```
2. Provision and boot the machine:
   ```ps1
   # use --color for better output readability
   vagrant up
   ```
3. SSH into the box:
   ```ps1
   vagrant ssh
   ```

### OpenTofu Environments
1. Navigate to your target deployment directory:
   ```ps1
   cd opentofu/hyper-v/kali
   ```
2. Initialize the provider plugins:
   ```ps1
   tofu init
   ```
3. Generate and review the execution plan:
   ```ps1
   tofu plan
   ```
4. Review the execution plan and deploy:
   ```ps1
   tofu apply
   ```

---

## Contributing

Feel free to fork the repository and submit pull requests for improvements, additional machine configurations, or new provider support. Please ensure that any contributions adhere to the existing code style and include appropriate documentation.

## Resources

- [Opentofu provider for Hyper-V](https://search.opentofu.org/provider/taliesins/hyperv/latest)
- [Vagrant](https://developer.hashicorp.com/vagrant/docs)
- [OpenTofu](https://opentofu.org/)

## License

Licensed under the [MIT](LICENSE) License.