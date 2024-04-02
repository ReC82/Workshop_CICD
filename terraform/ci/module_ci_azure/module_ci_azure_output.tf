output "private_key" {
  value     = tls_private_key.ssh_key_linux_openssh.private_key_pem
  sensitive = true
}

output "controller_ip" {
  value = azurerm_public_ip.pubip_controller.ip_address
}

output "private_ip_addresses" {
  value = {
    for idx, nic in azurerm_network_interface.nic_prod_nodes : idx => nic.ip_configuration[0].private_ip_address
  }
}

output "webapp_ip" {
    value = azurerm_public_ip.pubip_node_web.ip_address
}