output "private_ip_addresses" {
  value = join(";", [for idx, nic in azurerm_network_interface.nic_agents: nic.ip_configuration[0].private_ip_address])
}

output "private_ip_addresses_mapping" {
  value = join(";", [
    for idx, nic in azurerm_network_interface.nic_agents : 
    "${"TheAgent-${idx}"},${nic.ip_configuration[0].private_ip_address}"
  ])
}

output "agents_private_ips" {
  value = {
    for ni in azurerm_network_interface.nic_agents :
      ni.name => ni.private_ip_address
  }
}