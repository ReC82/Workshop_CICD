######################################
# CONTROLLER - NETWORK
######################################

resource "azurerm_virtual_network" "vnet_prod_controller" {
  name                = "vnet_${var.environment_control}"
  resource_group_name = var.group_name
  address_space       = var.env_space_cidr_control
  location            = var.group_location
}

resource "azurerm_subnet" "subnet_prod_controller" {
  name                 = "subnet_controller_${var.environment_control}_internal"
  resource_group_name  = var.group_name
  virtual_network_name = azurerm_virtual_network.vnet_prod_controller.name
  address_prefixes     = var.env_subnet_space_cidr_control
  depends_on = [ azurerm_virtual_network.vnet_prod_controller ]
}

resource "azurerm_network_interface" "nic_prod_controller" {
  name                = "nic_${var.environment_control}"
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
  domain_name_label   = "jenkins-lodydjango"
}


resource "azurerm_linux_virtual_machine" "Controller" {
  name                = "TheController"
  resource_group_name = var.group_name
  location            = var.group_location
  size                = "Standard_DS1_v2"
  admin_username      = var.root_user_name
  admin_password      = var.root_user_password
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_prod_controller.id
  ]

  os_disk {
    name                 = "ControllerDisk-a"
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
    public_key = var.root_user_public_key #tls_private_key.ssh_key_linux_openssh.public_key_openssh
  }
}

########################################################
# CONTROLLER SECURITY RULES
########################################################

resource "azurerm_network_security_group" "prod_security_group_controller" {
  name                = "${var.environment_control}_security_group"
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
    destination_address_prefix = "*" //azurerm_subnet.subnet_prod_controller.address_prefixes[0]
  }
  security_rule {
    name                       = "HTTP-JENKINS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet_prod_controller.address_prefixes[0]
  }
  tags = {
    env = "Control"
  }
}
# Association
resource "azurerm_network_interface_security_group_association" "prod_sga_controller" {
  network_interface_id      = azurerm_network_interface.nic_prod_controller.id
  network_security_group_id = azurerm_network_security_group.prod_security_group_controller.id
  depends_on                = [azurerm_network_security_group.prod_security_group_controller, azurerm_network_interface.nic_prod_controller]
}