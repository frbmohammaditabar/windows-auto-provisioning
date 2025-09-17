✅ Usage

Export Vault token and address:

export VAULT_ADDR='https://vault.example.com:8200'
export VAULT_TOKEN='s.xxxxxx'


Initialize and apply Terraform:

terraform init
terraform plan -var "vault_token=${VAULT_TOKEN}" -out plan.tf
terraform apply plan.tf


This will create:

Windows VMs on Proxmox

Dynamic Ansible inventory (inventory.ini) with Vault credentials
Then run Ansible playbook:

ansible-playbook -i ansible/inventory.ini ansible/playbooks/windows_roles.yml
