# Configure the Azure provider
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
terraform {

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # https://developer.hashicorp.com/terraform/language/expressions/version-constraints
      version = "3.95.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }

  #https://developer.hashicorp.com/terraform/language/settings
  required_version = ">= 1.1.0"
}

resource "azurerm_resource_group" "prod_group" {
  name = var.group_name
  # Where find those location ? https://github.com/claranet/terraform-azurerm-regions/blob/master/REGIONS.md 
  location = var.group_location
}

resource "azurerm_virtual_network" "vnet_prod" {
  name                = "vnet_${var.environment}"
  resource_group_name = var.group_name
  address_space       = var.env_space_cidr
  location            = var.group_location
  depends_on          = [azurerm_resource_group.prod_group]
}

resource "azurerm_subnet" "subnet_prod" {
  name                 = "subnet_${var.environment}_internal"
  resource_group_name  = var.group_name
  virtual_network_name = azurerm_virtual_network.vnet_prod.name
  address_prefixes     = var.env_subnet_space_cidr
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
    public_ip_address_id          = azurerm_public_ip.pubip_node_serve[count.index].id
  }
  depends_on = [azurerm_resource_group.prod_group]
}

resource "azurerm_public_ip" "pubip_node_serve" {
  count               = var.node_count
  name                = "pubip_node_${count.index}"
  resource_group_name = var.group_name
  location            = var.group_location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
  depends_on = [azurerm_resource_group.prod_group]
}

resource "azurerm_network_interface" "nic_prod_controller" {
  name                = "nic_${var.environment}_controller"
  resource_group_name = var.group_name
  location            = var.group_location
  ip_configuration {
    name                          = "nic_controller_config"
    subnet_id                     = azurerm_subnet.subnet_prod.id
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
# Ansible SecGroup
#########################
resource "azurerm_network_security_group" "prod_security_group" {
  name                = "${var.environment}_security_group"
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
    destination_address_prefix = azurerm_subnet.subnet_prod.address_prefixes[0]
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

resource "azurerm_network_interface_security_group_association" "prod_sga_controller" {
  network_interface_id      = azurerm_network_interface.nic_prod_controller.id
  network_security_group_id = azurerm_network_security_group.prod_security_group.id
  depends_on                = [azurerm_network_security_group.prod_security_group, azurerm_network_interface.nic_prod_controller]
}

resource "azurerm_network_interface_security_group_association" "prod_sga_nodes" {
  for_each = { for idx, nic in azurerm_network_interface.nic_prod_nodes : idx => nic }

  network_interface_id      = each.value.id
  network_security_group_id = azurerm_network_security_group.prod_security_group.id
  depends_on                = [azurerm_network_interface.nic_prod_nodes, azurerm_network_security_group.prod_security_group]
}




