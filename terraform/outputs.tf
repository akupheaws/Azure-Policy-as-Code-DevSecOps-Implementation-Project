output "vm_ids" {
  description = "IDs of all VMs"
  value       = { for k, v in azurerm_linux_virtual_machine.vm : k => v.id }
}

output "public_ips" {
  description = "Public IPs of all VMs"
  value       = { for k, v in azurerm_public_ip.pip : k => v.ip_address }
}

output "private_ips" {
  description = "Private IPs of all NICs"
  value       = { for k, v in azurerm_network_interface.nic : k => v.private_ip_address }
}
