variable "environment_name" {}

variable "environment_vnet_addr_space_suffix" {}

variable "root_user_name" {}

variable "root_user_password" {}

variable "root_user_public_key" {}

variable "root_user_private_key" {}

variable "resource_group_name" {}

variable "resource_location" {}

variable "node_count" {
  description = "Number of nodes"
  type        = number
}

variable "nodes_configuration" {
  description = "Array of maps containing node names and subnets"
  type        = list(object({
    node_name    = string
    subnet  = list(string)
    ip_address = string
    count = number
  }))
}

variable "vm_configuration" {
  type = map(object({
    category_name       = string
    subnet_address_prefix = string
    function            = string
    count               = number
  }))
  default = {
    web = {
      category_name       = "Web Servers"
      subnet_address_prefix = "10.0.1.0/24"
      function            = "web-server"
      count               = 1
    }
    database = {
      category_name       = "Database Servers"
      subnet_address_prefix = "10.0.2.0/24"
      function            = "database-server"
      count               = 1
    }
    api = {
      category_name       = "API Servers"
      subnet_address_prefix = "10.0.3.0/24"
      function            = "api-server"
      count               = 2
    }
  }
}

variable "controller_ip" {
  description = "IP From the controller"
}
