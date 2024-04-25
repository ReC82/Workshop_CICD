variable "security_group_name" {}
variable "resource_group" {}
variable "resource_location" {}

variable "rules_configuration" {
  description = "Array of maps containing rules"
  type        = list(object({
    name    = string
    access  = string
    source_port_range = string
    source_address_prefix = string
    protocol=string
    destination_port_range = string
    destination_address_prefix = string
    direction = string
  }))
}

variable "network_interface_id" {}