provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "win2022" {
  name   = "win2022-${var.vm_name}.qcow2"
  pool   = "default"
  source = "/var/lib/libvirt/images/win2022-template.qcow2"
  format = "qcow2"
}

resource "libvirt_domain" "win2022" {
  name   = "win2022-${var.vm_name}"
  memory = 8192
  vcpu   = 4

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.win2022.id
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }

  provisioner "local-exec" {
    command = <<EOT
      ansible-playbook -i '${self.network_interface.0.addresses.0},' \
      -u Administrator --extra-vars "ansible_password=${var.admin_password}" \
      playbooks/${var.role}.yaml
    EOT
  }
}
