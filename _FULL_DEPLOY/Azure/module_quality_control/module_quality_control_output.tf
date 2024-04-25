output "pubip_quality_control" {
  value = azurerm_public_ip.pubip_quality_control.ip_address
}

output "quality_controller_dns" {
  value = azurerm_public_ip.pubip_quality_control.fqdn
}

output "quality_controller_priv_addrr" {
  value = azurerm_network_interface.nic_quality_control.private_ip_address
}
