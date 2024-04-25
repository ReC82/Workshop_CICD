# Peering connection from vnet_prod to vnet_prod_controller
resource "azurerm_virtual_network_peering" "vnet_prod_to_controller" {
  name                         = var.peering_name
  resource_group_name          = var.peering_group_name
  virtual_network_name         = var.vnet_source_name
  remote_virtual_network_id    = var.vnet_destination_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

}