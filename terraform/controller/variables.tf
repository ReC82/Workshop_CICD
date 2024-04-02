variable "env_space_cidr_vnet_controller" {
  description = "Address Space Controller"
  default     = "10.0.0.0/16"
}

variable "env_subnet_space_cidr_controller" {
  description = "Address Space Subnet Controller"
  default     = "10.0.1.0/24"
}

variable "group_location" {
  default = "centralus"
}

variable "aws_ami" {
    default = "ami-08116b9957a259459"
}