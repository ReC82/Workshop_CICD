output "private_ip_addresses" {
  value = join(";", [for idx, nic in azurerm_network_interface.nics: nic.ip_configuration[0].private_ip_address])
}

output "private_ip_addresses_mapping" {
  value = join(";", [
    for idx, nic in azurerm_network_interface.nics : 
    "${nic.name},${nic.ip_configuration[0].private_ip_address}"
  ])
}

output "prod_private_ips" {
  value = {
    for ni in azurerm_network_interface.nics :
      ni.name => ni.private_ip_address
  }
}

output "webapp_ip" {
    value = azurerm_public_ip.pubip_node_web.ip_address
}


output "vnet_name" {
  value = azurerm_virtual_network.vnets.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnets.id  
}

output "env_name" {
  value = var.environment_name
}

# Export All the NICS IDS

output "all_nics_ids" {
  value = {
    for nic_key, nic in azurerm_network_interface.nics : nic_key => nic.id
  }
}
