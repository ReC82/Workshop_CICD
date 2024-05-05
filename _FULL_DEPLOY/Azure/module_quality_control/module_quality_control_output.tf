output "pubip_quality_control" {
  value = azurerm_public_ip.pubip_quality_control.ip_address
}

output "quality_controller_dns" {
  value = azurerm_public_ip.pubip_quality_control.fqdn
}

output "private_ip_addresses" {
  value = azurerm_network_interface.nic_quality_control.private_ip_address
}

output "quality_private_ips" {
  value = {
    for ni in [azurerm_network_interface.nic_quality_control]:
      ni.name => ni.private_ip_address
  }
}

/*
If multiple 
output "private_ip_addresses" {
  value = join(";", [for idx, nic in azurerm_network_interface.nic_quality_control: nic.ip_configuration[0].private_ip_address])
}
*/
