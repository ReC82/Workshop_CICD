######################################
# AGENTS - NETWORK
######################################

resource "azurerm_subnet" "subnet_agents" {
  name                 = "subnet_agents_${var.environment_name}_internal"
  resource_group_name  = var.group_name
  virtual_network_name = var.controller_vnet_name
  address_prefixes     = var.env_subnet_space_cidr_control
}

resource "azurerm_network_interface" "nic_agents" {
  count               = var.agents_count
  name                = "nic_${var.environment_name}_${count.index}"
  resource_group_name = var.group_name
  location            = var.group_location

  ip_configuration {
    name                          = "nic_agent_config_${count.index}"
    subnet_id                     = azurerm_subnet.subnet_agents.id
    private_ip_address_allocation = "Dynamic"
  }
}

locals {
  custom_data = <<CUSTOM_DATA
  #!/bin/bash
  mkdir -p /home/${var.root_user_name}/.ssh
  # Temporarly Create Jenkins Home Here
  mkdir -p /home/jenkins/.ssh
  echo "${var.controller_public_key}" >> /home/${var.root_user_name}/.ssh/authorized_keys
  echo "${var.controller_public_key}" >> /home/jenkins/.ssh/authorized_keys
  CUSTOM_DATA
  }

resource "azurerm_linux_virtual_machine" "Agents" {
  count               = var.agents_count
  name                = "TheAgent-${count.index}"
  resource_group_name = var.group_name
  location            = var.group_location
  size                = "Standard_B1s"
  admin_username      = var.root_user_name
  admin_password      = var.root_user_password
  #disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.nic_agents[count.index].id
  ]

  os_disk {
    name                 = "AgentDisk-${count.index}"
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

  custom_data = base64encode(local.custom_data)
  depends_on = [ azurerm_network_interface.nic_agents ]
}

########################################################
# AGENTS SECURITY RULES
########################################################

resource "azurerm_network_security_group" "agents_secgroup" {
  name                = "${var.environment_name}_security_group"
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
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "prod_sga_controller" {
  count                      = var.agents_count
  network_interface_id       = azurerm_network_interface.nic_agents[count.index].id
  network_security_group_id  = azurerm_network_security_group.agents_secgroup.id
  depends_on                 = [
    azurerm_network_security_group.agents_secgroup,
    azurerm_network_interface.nic_agents
  ]
}
