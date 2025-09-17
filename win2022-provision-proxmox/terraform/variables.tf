variable "proxmox_api_url" {
  description = "Proxmox API URL, e.g. https://proxmox.example.com:8006/api2/json"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox user (root@pam or api token format user@pve!tokenid)"
  type        = string
}

variable "proxmox_password" {
  description = "Proxmox password (or API token secret). Ideally pass via -var or env"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Set true to allow insecure TLS (self-signed Proxmox)"
  type        = bool
  default     = true
}

variable "node" {
  type    = string
  default = "pve"
}

variable "template_vm_id" {
  description = "Proxmox VMID of the Windows template to clone from (must be a template)"
  type        = number
}

variable "name" {
  type = string
}

variable "vcpus" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_model" {
  type    = string
  default = "e1000" # safe default for Windows
}

variable "enable_qemu_agent" {
  type    = bool
  default = true
}
