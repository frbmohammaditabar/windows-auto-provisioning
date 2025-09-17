variable "libvirt_uri"    { default = "qemu:///system" }
variable "template_path"  { type = string }
variable "name"           { type = string }
variable "network_name"   { default = "default" }
variable "storage_pool"   { default = "default" }
variable "memory_mb"      { default = 8192 }
variable "vcpus"          { default = 4 }
variable "role"           { type = string }
variable "ansible_playbook_path" { type = string }

# Vault integration
variable "vault_addr"  { type = string }
variable "vault_token" { type = string }
