output "controller_ip" {
  value = azurerm_public_ip.pubip_controller.ip_address
}

output "controller_dns" {
  value = azurerm_public_ip.pubip_controller.fqdn
}

output "control_vnet_id" {
  value = azurerm_virtual_network.vnet_prod_controller.id
}

output "control_vnet_name" {
  value = azurerm_virtual_network.vnet_prod_controller.name
}
