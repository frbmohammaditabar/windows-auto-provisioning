module "win_dc" {
  source = "../modules/windows_vm"

  name                 = "win-dc-01"
  template_path        = "/var/lib/libvirt/images/win2k22-temp.qcow2"
  admin_password       = var.vm_admin_password
  role                 = "domain_controller"
  ansible_playbook_path = "/home/faribamohammaditabar/Proxmox/win2022-provision/ansible/playbooks"   # adjust
}
