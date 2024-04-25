variable "env_quality_control" {
  description = "Quality Control Env."
  default     = "quality"
}

variable "control_vnet_name" {}

variable "env_space_cidr_qualitycontrol" {
  description = "Address Space Quality Control Prod Env"
  default     = ["10.1.0.0/16"]
}

variable "env_subnet_space_cidr_qualitycontrol" {
  description = "Address Space Subnet Prod Env"
  default     = ["10.1.5.0/24"]
}

variable "root_user_name" {}

variable "root_user_password" {}

variable "root_user_public_key" {}

variable "root_user_private_key" {}

variable "git_private_key" {}

variable "git_global_private_key" {}

variable "group_location" {}

variable "group_name" {}










