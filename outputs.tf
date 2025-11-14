# Output values

output "vm_name" {
  value       = libvirt_domain.vm.name
  description = "Name of the VM"
}

output "vm_id" {
  value       = libvirt_domain.vm.id
  description = "ID of the VM domain"
}

output "vm_ip" {
  value       = var.vm_static_ip
  description = "Configured static IP for the VM (may differ from actual DHCP assigned IP)"
}

output "vm_mac" {
  value       = "Use 'sudo virsh domiflist ${libvirt_domain.vm.name}' to get actual MAC address"
  description = "Command to get VM MAC address"
}

output "console_access" {
  value       = "sudo virsh console ${libvirt_domain.vm.name}"
  description = "Command to access VM console"
}

output "ssh_command" {
  value       = "ssh ubuntu@<VM_IP> # Get IP with 'make vm-ip'"
  description = "SSH access command (replace <VM_IP> with actual IP)"
}

output "ansible_inventory" {
  value       = var.enable_ansible ? "${path.module}/ansible/inventory.ini" : "Ansible disabled"
  description = "Path to generated Ansible inventory file"
}

output "ansible_command" {
  value       = var.enable_ansible ? "cd ansible && ansible-playbook playbook.yml" : "Ansible disabled"
  description = "Command to run Ansible playbook manually"
}