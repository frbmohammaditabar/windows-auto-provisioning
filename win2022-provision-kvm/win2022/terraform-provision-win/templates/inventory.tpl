[windows]
%{ for vm in vms ~}
${vm.name} ansible_user=${username} ansible_password=${password} ansible_connection=winrm ansible_winrm_transport=basic
%{ endfor ~}
