variable "environment_control" {
  description = "Control Env."
  default     = "control"
}

variable "env_space_cidr_control" {
  description = "Address Space Control Prod Env"
  default     = ["10.1.0.0/16"]
}

variable "env_subnet_space_cidr_control" {
  description = "Address Space Subnet Prod Env"
  default     = ["10.1.20.0/24"]
}

variable "root_user_name" {}

variable "root_user_password" {}

variable "root_user_public_key" {}

variable "root_user_private_key" {}

variable "git_private_key" {}

variable "git_global_private_key" {}

variable "group_location" {}

variable "group_name" {}










