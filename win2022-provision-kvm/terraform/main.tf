terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}


# Clone VM from Windows qcow2 template
resource "libvirt_volume" "win_clone" {
  name   = "${var.name}.qcow2"
  pool   = var.storage_pool
  source = var.template_path
  format = "qcow2"
}

# Define Windows VM
resource "libvirt_domain" "vm" {
  name   = var.name
  memory = var.memory_mb
  vcpu   = var.vcpus

  network_interface {
    network_name   = var.network_name
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.win_clone.id
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }

  # Run Ansible after VM boot
#  provisioner "local-exec" {
#    command = "bash ${path.module}/templates/run_ansible.sh ${self.network_interface.0.addresses.0} ${var.role} ${var.ansible_playbook_path}"

    # Pass Vault env variables to the script
 #   environment = {
 #     VAULT_ADDR  = var.vault_addr
 #     VAULT_TOKEN = var.vault_token
 #   }

  #  interpreter = ["/bin/bash", "-c"]
#  }
}
