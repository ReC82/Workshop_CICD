output "monitoring_private_ip_addresses" {
  value = azurerm_network_interface.nic_monitoring.private_ip_address
}