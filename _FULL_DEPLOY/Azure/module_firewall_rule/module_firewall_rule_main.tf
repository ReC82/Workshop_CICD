resource "azurerm_network_security_group" "firewall_rule" {
  name                = var.security_group_name
  location            = var.resource_location
  resource_group_name = var.resource_group

  dynamic "security_rule" {
    for_each = var.rules_configuration
    content {
      name                       = security_rule.value.name
      priority                   = 100 + security_rule.key
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
