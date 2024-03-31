resource "azurerm_resource_group" "prod_group" {
  name = var.group_name
  # Where find those location ? https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md 
  location = var.group_location
}

################################################
# NODES - PRODUCTION - NETWORK
################################################
resource "azurerm_virtual_network" "vnet_prod" {
  name                = "vnet_${var.environment}"
  resource_group_name = var.group_name
  address_space       = var.env_space_cidr_nodes
  location            = var.group_location
  depends_on          = [azurerm_resource_group.prod_group]
}

resource "azurerm_subnet" "subnet_prod" {
  name                 = "subnet_${var.environment}_internal"
  resource_group_name  = var.group_name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = var.env_space_cidr_nodes
  depends_on           = [azurerm_resource_group.prod_group]
}

resource "azurerm_network_interface" "nic_prod_nodes" {
  count               = var.node_count
  name                = "nic_${var.environment}_node_${count.index}"
  resource_group_name = var.group_name
  location            = var.group_location
  ip_configuration {
    name                          = "nic_node_${count.index}_config"
    subnet_id                     = azurerm_subnet.subnet_prod.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${10 + count.index}"
    public_ip_address_id          = count.index == 0 ? azurerm_public_ip.pubip_node_web.id : null
  }
  depends_on = [azurerm_resource_group.prod_group, azurerm_public_ip.pubip_node_web]
}

resource "azurerm_public_ip" "pubip_node_web" {
  name                = "pubip_node_web"
  resource_group_name = var.group_name
  location            = var.group_location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_resource_group.prod_group]
}

######################################
# CONTROLLER - NETWORK - PRODUCTION
######################################

resource "azurerm_virtual_network" "vnet_prod_controller" {
  name                = "vnet_${var.environment}_controller"
  resource_group_name = var.group_name
  address_space       = var.env_space_cidr_control
  location            = var.group_location
  depends_on          = [azurerm_resource_group.prod_group]
}

resource "azurerm_subnet" "subnet_prod_controller" {
  name                 = "subnet_controller_${var.environment}_internal"
  resource_group_name  = var.group_name
  virtual_network_name = azurerm_virtual_network.vnet_prod_controller.name
  address_prefixes     = var.env_subnet_space_cidr_control
  depends_on           = [azurerm_resource_group.prod_group]
}

resource "azurerm_network_interface" "nic_prod_controller" {
  name                = "nic_${var.environment}_controller"
  resource_group_name = var.group_name
  location            = var.group_location
  ip_configuration {
    name                          = "nic_controller_config"
    subnet_id                     = azurerm_subnet.subnet_prod_controller.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip_controller.id
  }
}

resource "azurerm_public_ip" "pubip_controller" {
  name                = "pubip_controller"
  resource_group_name = var.group_name
  location            = var.group_location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_resource_group.prod_group]
}

#####################
# SSH KEY
#####################
resource "tls_private_key" "ssh_key_linux_openssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#####################
# SSH KEY - EXPORT
#####################
resource "local_file" "export_private_key" {
  content    = tls_private_key.ssh_key_linux_openssh.private_key_pem
  filename   = "priv.pem"
  depends_on = [tls_private_key.ssh_key_linux_openssh]
}

resource "local_file" "export_public_key" {
  content    = tls_private_key.ssh_key_linux_openssh.public_key_openssh
  filename   = "public.pub"
  depends_on = [tls_private_key.ssh_key_linux_openssh]
}

resource "azurerm_linux_virtual_machine" "nodecontroller" {
  name                = "nodecontroller"
  resource_group_name = var.group_name
  location            = var.group_location
  size                = "Standard_DS1_v2"
  admin_username      = "rooty"
  admin_password      = "P@ssw0rd!123"
  #disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_prod_controller.id
  ]

  os_disk {
    name                 = "NodeControlDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "rooty"
    public_key = tls_private_key.ssh_key_linux_openssh.public_key_openssh
  }
}

resource "azurerm_linux_virtual_machine" "nodes" {
  count                           = var.node_count
  name                            = "node-${var.node_names[count.index]}${format("%02d", count.index + 1)}"
  resource_group_name             = var.group_name
  location                        = var.group_location
  size                            = "Standard_DS1_v2"
  admin_username                  = var.root_user_name
  admin_password                  = var.root_user_password
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_prod_nodes[count.index].id
  ]

  os_disk {
    name                 = "node${count.index}Disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "rooty"
    public_key = tls_private_key.ssh_key_linux_openssh.public_key_openssh
  }
}

#########################
# NODES - SECURITY RULES
#########################
resource "azurerm_network_security_group" "prod_security_group_nodes" {
  name                = "${var.environment}_security_group_nodes"
  location            = var.group_location
  resource_group_name = var.group_name
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.env_subnet_space_cidr_control[0]
    destination_address_prefix = var.env_subnet_space_cidr_nodes[0]
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
    env = "Production"
  }
  depends_on = [azurerm_resource_group.prod_group]
}
# Association
resource "azurerm_network_interface_security_group_association" "prod_sga_nodes" {
  for_each = { for idx, nic in azurerm_network_interface.nic_prod_nodes : idx => nic }

  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.prod_security_group_nodes.id
  depends_on                = [azurerm_network_interface.nic_prod_nodes, azurerm_network_security_group.prod_security_group_nodes]
}

########################################################
# CONTROLLER SECURITY RULES
########################################################

resource "azurerm_network_security_group" "prod_security_group_controller" {
  name                = "${var.environment}_security_group_controller"
  location            = var.group_location
  resource_group_name = var.group_name
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet_prod_controller.address_prefixes[0]
  }

  tags = {
    env = "Production"
  }
  depends_on = [azurerm_resource_group.prod_group]
}
# Association
resource "azurerm_network_interface_security_group_association" "prod_sga_controller" {
  network_interface_id      = azurerm_network_interface.nic_prod_controller.id
  network_security_group_id = azurerm_network_security_group.prod_security_group_controller.id
  depends_on                = [azurerm_network_security_group.prod_security_group_controller, azurerm_network_interface.nic_prod_controller]
}

##########################################################
#  Peering to access nodes from Controller
##########################################################

# Peering connection from vnet_prod_controller to vnet_prod
resource "azurerm_virtual_network_peering" "vnet_controller_to_prod" {
  name                         = "vnet-controller-to-prod"
  resource_group_name          = var.group_name
  virtual_network_name         = azurerm_virtual_network.vnet_prod_controller.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_prod.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_resource_group.prod_group]
}

# Peering connection from vnet_prod to vnet_prod_controller
resource "azurerm_virtual_network_peering" "vnet_prod_to_controller" {
  name                         = "vnet-prod-to-controller"
  resource_group_name          = var.group_name
  virtual_network_name         = azurerm_virtual_network.vnet_prod.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet_prod_controller.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = false
  allow_gateway_transit        = false
  use_remote_gateways          = false

  depends_on = [azurerm_resource_group.prod_group]
}


