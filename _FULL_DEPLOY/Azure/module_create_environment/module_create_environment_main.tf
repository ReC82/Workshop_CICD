################################################
# NODES - PRODUCTION - NETWORK
################################################
resource "azurerm_virtual_network" "vnets" {
  name                = "vnet_${var.environment_name}"
  resource_group_name = var.resource_group_name
  address_space       = [var.environment_vnet_addr_space_suffix]
  location            = var.resource_location
}

################################################
# SUBNETS
################################################
locals {
  subnet_configurations = {
    for node_config in var.nodes_configuration : node_config.node_name => {
      name             = "subnet_${var.environment_name}_${node_config.node_name}"
      address_prefixes = node_config.subnet
      count            = node_config.count
    }
  }
}

resource "azurerm_subnet" "subnets_dynamic" {
  for_each            = local.subnet_configurations
  name                = each.value.name
  resource_group_name = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnets.name
  address_prefixes    = each.value.address_prefixes
}

resource "azurerm_network_interface" "nics" {
  for_each             = local.subnet_configurations

  name                 = "nic_${var.environment_name}_${each.key}"
  resource_group_name  = var.resource_group_name
  location             = var.resource_location

  dynamic "ip_configuration" {
    for_each = range(each.value.count)

    content {
      name                          = "nic_${var.environment_name}_${each.key}_config_${ip_configuration.key}"
      subnet_id                     = azurerm_subnet.subnets_dynamic[each.key].id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = each.key == "web" ? azurerm_public_ip.pubip_node_web.id : null
    }
  }
  depends_on = [ azurerm_public_ip.pubip_node_web ]
}


resource "azurerm_public_ip" "pubip_node_web" {
  name                = "pubip_node_web"
  resource_group_name = var.resource_group_name
  location            = var.resource_location
  allocation_method   = "Static"
}

resource "azurerm_linux_virtual_machine" "nodes" {
  count                           = length(local.subnet_configurations)
  name                            = "node-${keys(local.subnet_configurations)[count.index]}${format("%02d", count.index + 1)}"
  resource_group_name             = var.resource_group_name
  location                        = var.resource_location
  size                            = "Standard_B1s"
  admin_username                  = var.root_user_name
  admin_password                  = var.root_user_password
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nics[keys(local.subnet_configurations)[count.index]].id
  ]

  os_disk {
    name                 = "node${count.index}Disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = var.root_user_name
    public_key = var.root_user_public_key
  }
}





#########################
# NODES - SECURITY RULES
#########################
resource "azurerm_network_security_group" "prod_security_group_nodes" {
  name                = "${var.environment_name}_security_group_nodes"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.controller_ip
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP-APP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.1.10/32"
  }
  security_rule {
    name                       = "HTTP-API"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "10.0.1.10/32"
    destination_address_prefix = "10.0.1.11/32"
  }
  security_rule {
    name                       = "MYSQL"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.1.11/32"
    destination_address_prefix = "10.0.1.12/32"
  }

  tags = {
    env = "${var.environment_name}"
  }
}
# Association
resource "azurerm_network_interface_security_group_association" "SecGroupAssoc" {
  for_each = { for idx, nic in azurerm_network_interface.nics : idx => nic }

  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.prod_security_group_nodes.id
  depends_on                = [azurerm_network_interface.nics]
}




