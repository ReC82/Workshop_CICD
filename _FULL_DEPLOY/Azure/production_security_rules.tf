variable "production_security_rules" {
  default = [
    {
      name                       = "HTTP_ACCESS"
      access                     = "Allow"
      source_port_range          = "*"
      source_address_prefix      = "*"
      protocol                   = "Tcp"
      destination_port_range     = "80"
      destination_address_prefix = "*"
      direction                  = "Inbound"
    },
    {
      name                       = "DB_ACCESS"
      access                     = "Allow"
      direction                  = "Inbound"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3306"
      source_address_prefix      = "10.0.1.11/32"
      destination_address_prefix = "10.0.1.12/32"
    },
    {
      name                       = "API_ACCESS"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "10.0.1.10/32"
      destination_address_prefix = "10.0.1.11/32"
    },
    {
      name                       = "SSH_ACCESS"
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "10.0.1.11/32"
      destination_address_prefix = "10.0.1.12/32"
    }
  ]
}

