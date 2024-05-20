######################################
# QUALITY CONTROL - NETWORK
######################################

resource "azurerm_subnet" "subnet_quality_control" {
  name                 = "subnet_controller_${var.env_quality_control}_internal"
  resource_group_name  = var.group_name
  virtual_network_name = var.control_vnet_name
  address_prefixes     = var.env_subnet_space_cidr_qualitycontrol
}

resource "azurerm_network_interface" "nic_quality_control" {
  name                = "nic_${var.env_quality_control}"
  resource_group_name = var.group_name
  location            = var.group_location
  ip_configuration {
    name                          = "nic_qualitycontrol_config"
    subnet_id                     = azurerm_subnet.subnet_quality_control.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip_quality_control.id
  }
}

resource "azurerm_public_ip" "pubip_quality_control" {
  name                = "pubip_quality_control"
  resource_group_name = var.group_name
  location            = var.group_location
  allocation_method   = "Static"
  domain_name_label   = "qualitycontrol-lodydjango"
}


resource "azurerm_linux_virtual_machine" "QualityControl" {
  name                = "QualityController"
  resource_group_name = var.group_name
  location            = var.group_location
  size                = "Standard_DS1_v2"
  admin_username      = var.root_user_name
  admin_password      = var.root_user_password
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_quality_control.id
  ]

  os_disk {
    name                 = "QualityControl-Disk"
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
# QUALITY CONTROL SECURITY RULES
########################################################

resource "azurerm_network_security_group" "prod_security_group_qualitycontrol" {
  name                = "${var.env_quality_control}_security_group"
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
    destination_address_prefix = "*" //azurerm_subnet.subnet_quality_control.address_prefixes[0]
  }
  security_rule {
    name                       = "HTTP-SONARQUBE"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet_quality_control.address_prefixes[0]
  }
  tags = {
    env = "Control"
  }
}
# Association
resource "azurerm_network_interface_security_group_association" "prod_sga_qualitycontrol" {
  network_interface_id      = azurerm_network_interface.nic_quality_control.id
  network_security_group_id = azurerm_network_security_group.prod_security_group_qualitycontrol.id
  depends_on                = [azurerm_network_security_group.prod_security_group_qualitycontrol, azurerm_network_interface.nic_quality_control]
}