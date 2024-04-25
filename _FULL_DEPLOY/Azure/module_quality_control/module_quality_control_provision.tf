output "qc_private_ip_addresses" {
  value = azurerm_network_interface.nic_quality_control.private_ip_address
}