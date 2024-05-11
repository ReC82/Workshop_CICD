######################################
# MONITORING - NETWORK
######################################

resource "azurerm_subnet" "subnet_monitoring" {
  name                 = "subnet_controller_${var.env_monitoring}_internal"
  resource_group_name  = var.group_name
  virtual_network_name = var.monitoring_vnet_name
  address_prefixes     = var.env_subnet_space_cidr_monitoring
}

resource "azurerm_network_interface" "nic_monitoring" {
  name                = "nic_${var.env_monitoring}"
  resource_group_name = var.group_name
  location            = var.group_location
  ip_configuration {
    name                          = "nic_monitoring_config"
    subnet_id                     = azurerm_subnet.subnet_monitoring.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip_monitoring.id
  }
}

resource "azurerm_public_ip" "pubip_monitoring" {
  name                = "pubip_monitoring"
  resource_group_name = var.group_name
  location            = var.group_location
  allocation_method   = "Static"
  domain_name_label   = "monitoring-lodycicd"
}


resource "azurerm_linux_virtual_machine" "HealthMonitor" {
  name                = "HealthMonitor"
  resource_group_name = var.group_name
  location            = var.group_location
  size                = "Standard_B1s"
  admin_username      = var.root_user_name
  admin_password      = var.root_user_password
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_monitoring.id
  ]

  os_disk {
    name                 = "HealthMonitor-Disk"
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
# MONITORING SECURITY RULES
########################################################

resource "azurerm_network_security_group" "prod_security_group_monitoring" {
  name                = "${var.env_monitoring}_security_group"
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
    destination_address_prefix = "*" //azurerm_subnet.subnet_monitoring.address_prefixes[0]
  }
  security_rule {
    name                       = "HTTP-Nagios"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet_monitoring.address_prefixes[0]
  }
  security_rule {
    name                       = "HTTP-Grafana"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet_monitoring.address_prefixes[0]
  }  
  security_rule {
    name                       = "HTTP-Prometheus"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = azurerm_subnet.subnet_monitoring.address_prefixes[0]
  }
  tags = {
    env = "Control"
  }
}
# Association
resource "azurerm_network_interface_security_group_association" "prod_sga_monitoring" {
  network_interface_id      = azurerm_network_interface.nic_monitoring.id
  network_security_group_id = azurerm_network_security_group.prod_security_group_monitoring.id
  depends_on                = [azurerm_network_security_group.prod_security_group_monitoring, azurerm_network_interface.nic_monitoring]
}