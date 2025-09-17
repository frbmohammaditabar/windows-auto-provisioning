# Windows VM Provisioning on Proxmox VE with Terraform + Ansible

Author: Fariba Mohammaditabar
Last Update: 2025 Sep 17

This project automates the provisioning of **Windows Server VMs** on **Proxmox VE (KVM/libvirt)** using **Terraform** for VM lifecycle management and **Ansible** for post-install configuration.

---

## Features
- Clone Windows VM from a prebuilt **cloud-ready template** (`qcow2` image).
- Supports multiple roles:
  - Domain Controller (DC)
  - Admin Server
  - RDS Server
  - DFS Server
- Automates post-provisioning tasks using **Ansible** over WinRM.
- (Optional) Integrates with **HashiCorp Vault** for retrieving secrets like the Administrator password.

---

## Requirements

### On the Proxmox host
- Proxmox VE installed and configured  
- Libvirt + Terraform provider for Proxmox  
- Prebuilt **Windows Server cloud image template** (`qcow2`) with:
  - Cloudbase-Init
  - WinRM enabled
  - QEMU Guest Agent installed

### On the client (where Terraform runs)
- Terraform `>= 1.3`
- Ansible `>= 2.12`
- libvirt provider for Terraform
- (Optional) HashiCorp Vault CLI configured (`vault` command)

---

## Project Structure
```bash
.
├── terraform/
│ ├── main.tf # Terraform VM definition
│ ├── outputs.tf # Outputs (IP, etc.)
│ ├── variables.tf # Variables
│ └── templates/
│ └── run_ansible.sh # Helper script to run Ansible
└── ansible/
└── playbooks/
├── wait_for_winrm.yml
├── domain_controller.yml
├── admin_server.yml
├── rds_server.yml
└── dfs_server.yml
```
---

## Usage

### 1. Clone this repository
```bash
git clone https://github.com/windows-auto-provisioning/win-provision-proxmox.git
cd win-provision-proxmox/terraform
```
2. Initialize Terraform
```bash
terraform init
```
3. Create a Windows VM
```bash
terraform apply \
  -var 'template_path=/var/lib/libvirt/images/win2k22-template.qcow2' \
  -var 'ansible_playbook_path=/home/youruser/win-provision-proxmox/ansible/playbooks' \
  -var 'name=win-dc01' \
  -var 'role=dc'
```
4. Destroy a VM
```bash
terraform destroy -var 'name=win-dc01'
```
### Administrator Password Handling
By default, the script expects to fetch the password from Vault:

```bash
vault kv get -field=AdministratorPassword secret/win/admin
```
If you don’t use Vault:

Modify templates/run_ansible.sh to hardcode or pass via environment variable:

```bash
export WIN_ADMIN_PASS='YourPasswordHere'
```
### Troubleshooting
VM doesn’t boot correctly
→ Check if the Windows template was created with Cloudbase-Init and QEMU Guest Agent.

Terraform fails with couldn't retrieve IP address
→ Use a DHCP-enabled network (default libvirt network) or configure static IPs manually.

WinRM not reachable
→ Ensure the Windows template has WinRM enabled and the firewall allows inbound on port 5985.

Vault not found
→ Either install Vault CLI or remove Vault dependency from run_ansible.sh.

### Next Steps
Add support for static IP addressing.

Integrate with Proxmox API provider instead of libvirt (for native Proxmox users).

Expand Ansible roles for more Windows services.


### License
MIT License – feel free to use and adapt.
