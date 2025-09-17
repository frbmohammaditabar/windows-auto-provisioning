terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = var.proxmox_tls_insecure
}

# Clone VM from an existing Proxmox TEMPLATE (template must already exist)
resource "proxmox_vm_qemu" "win" {
  name        = var.name
  target_node = var.node
  clone       = var.template_vm_id

  # resources
  cores   = var.vcpus
  memory  = var.memory_mb
  scsihw  = "virtio-scsi-pci"

  # disk and sizing - optional to override; if omitted clone keeps template disk
  # disk {
  #   size = "50G"
  #   type = "scsi"
  # }

  # network - the clone will inherit the template network but you may override:
  network {
    model  = var.network_model      # e1000 or virtio (template must have matching drivers)
    bridge = var.network_bridge
  }

  # Optionally set cloud-init style ipconfig (works only if template has cloudbase-init)
  dynamic "agent" {
    for_each = var.enable_qemu_agent ? [1] : []
    content {
      enabled = true
    }
  }

  # Optionally set static IP via Proxmox ipconfig0 (if template uses cloudbase-init or cloud-init)
  lifecycle {
    ignore_changes = [network]
  }
}

output "vmid" {
  value = proxmox_vm_qemu.win.vmid
}

output "vm_name" {
  value = proxmox_vm_qemu.win.name
}
