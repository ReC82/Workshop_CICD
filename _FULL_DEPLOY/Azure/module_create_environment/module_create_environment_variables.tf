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
    count = number
  }))
}

variable "controller_ip" {
  description = "IP From the controller"
}
