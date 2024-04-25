variable "environment_name" {}
variable "agents_count" {}
variable "controller_vnet_name" {}

variable "env_subnet_space_cidr_control" {
  description = "Address Space Subnet Prod Env"
  default     = ["10.1.10.0/24"]
}

variable "root_user_name" {}

variable "root_user_password" {}

variable "root_user_public_key" {}

variable "root_user_private_key" {}

variable "group_location" {}

variable "group_name" {}

variable "controller_public_key" {}










