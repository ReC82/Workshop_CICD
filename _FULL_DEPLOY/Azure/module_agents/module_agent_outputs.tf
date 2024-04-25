output "private_ip_addresses" {
  value = join(";", [for idx, nic in azurerm_network_interface.nic_agents: nic.ip_configuration[0].private_ip_address])
}

output "private_ip_addresses_mapping" {
  value = join(";", [
    for idx, nic in azurerm_network_interface.nic_agents : 
    "${"TheAgent-${idx}"},${nic.ip_configuration[0].private_ip_address}"
  ])
}