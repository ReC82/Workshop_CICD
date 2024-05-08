output "pubip_monitoring_control" {
  value = azurerm_public_ip.pubip_monitoring.ip_address
}

output "monitoring_controller_dns" {
  value = azurerm_public_ip.pubip_monitoring.fqdn
}

output "private_ip_addresses" {
  value = azurerm_network_interface.nic_monitoring.private_ip_address
}

output "monitoring_private_ips" {
  value = {
    for ni in [azurerm_network_interface.nic_monitoring]:
      ni.name => ni.private_ip_address
  }
}

/*
If multiple 
output "private_ip_addresses" {
  value = join(";", [for idx, nic in azurerm_network_interface.nic_monitoring_control: nic.ip_configuration[0].private_ip_address])
}
*/
