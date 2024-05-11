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

output "private_ip_addresses" {
  value = azurerm_network_interface.nic_prod_controller.private_ip_address
}

output "control_private_ips" {
  value = {
    for ni in [azurerm_network_interface.nic_prod_controller]:
      ni.name => ni.private_ip_address
  }
}
