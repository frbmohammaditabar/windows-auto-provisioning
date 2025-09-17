Automated Windows Server Deployment with Terraform, Vault, and Ansible

Author: Fariba Mohammaditabar

This project automates the provisioning and configuration of Windows Server 2019/2022 virtual machines on KVM/libvirt, using Terraform for VM creation, Vault for secrets management, and Ansible for post-installation role-based configuration.

## Project Structure
.
├── terraform/                  # Terraform configs for VM provisioning
│   ├── main.tf                 # Libvirt provider and VM definition
│   ├── variables.tf            # Variables (network, storage, etc.)
│   └── outputs.tf              # Output VM IPs for Ansible inventory
│
├── ansible/
│   ├── inventory/              # Dynamic/static inventory
│   ├── group_vars/             # Vault lookup variables (domain, creds)
│   └── roles/                  # Role-based server configurations
│       ├── domain_controller/
│       ├── admin_server/
│       ├── rds/
│       └── dfs/
│
├── vault/
│   ├── policies/               # Vault ACL policies
│   └── secrets/                # Example secrets stored (passwords, keys)
│
└── README.md                   # This documentation

## Secrets Management (Vault)

All sensitive data (domain admin credentials, DNS settings, RDS keys, etc.) are stored in HashiCorp Vault.

Example secrets in Vault:
```bash
vault kv put secret/windows/domain domain_name="corp.local"
vault kv put secret/windows/admin username="Administrator" password="SuperSecure123!"
vault kv put secret/windows/dns primary="192.168.122.1" secondary="8.8.8.8"
```

Ansible retrieves secrets dynamically:
```yaml
# group_vars/all/vault.yml
domain_name: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=secret/windows/domain field=domain_name') }}"
admin_user:  "{{ lookup('community.hashi_vault.hashi_vault', 'secret=secret/windows/admin field=username') }}"
admin_pass:  "{{ lookup('community.hashi_vault.hashi_vault', 'secret=secret/windows/admin field=password') }}"
dns_primary: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=secret/windows/dns field=primary') }}"
dns_secondary: "{{ lookup('community.hashi_vault.hashi_vault', 'secret=secret/windows/dns field=secondary') }}"
```
### Deployment Workflow
1. Provision Windows VM with Terraform

Uses KVM/libvirt provider.

Deploys VM from qcow2 Windows Server template.

Passes cloud-init/ignition for initial setup.
```bash
cd terraform/
terraform init
terraform apply -auto-approve
```

Outputs will include the VM IP for Ansible:
```hcl
output "windows_vm_ip" {
  value = libvirt_domain.win_vm.network_interface[0].addresses[0]
}
```
2. Configure with Ansible

Run role-based playbooks:
```bash
cd ansible/

# Domain Controller
ansible-playbook -i inventory playbooks/domain_controller.yml

# Admin Server
ansible-playbook -i inventory playbooks/admin_server.yml

# RDS
ansible-playbook -i inventory playbooks/rds.yml

# DFS
ansible-playbook -i inventory playbooks/dfs.yml
```
### Features

Idempotent Ansible roles (safe re-runs).

Vault integration: no plaintext secrets in repo.

Role separation for services:

* domain_controller

* admin_server

* rds

* dfs

Error handling & retries built into Ansible plays.

Modular Terraform design for easy scaling.

## Requirements

Terraform >= 1.3

KVM/libvirt (with virt-manager or CLI)

Ansible >= 2.14 with community.hashi_vault plugin

Vault server (unsealed & initialized)

Windows Server 2019/2022 qcow2 image prepared with cloudbase-init

