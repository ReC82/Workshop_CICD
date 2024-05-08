variable "env_monitoring" {
  description = "Monitoring Control Env."
  default     = "Monitoring"
}

variable "monitoring_vnet_name" {}

variable "env_space_cidr_monitoring" {
  description = "Address Space Monitoring Env"
  default     = ["10.1.0.0/16"]
}

variable "env_subnet_space_cidr_monitoring" {
  description = "Address Space Subnet Prod Env"
  default     = ["10.1.6.0/24"]
}

variable "root_user_name" {}

variable "root_user_password" {}

variable "root_user_public_key" {}

variable "root_user_private_key" {}

variable "git_private_key" {}

variable "git_global_private_key" {}

variable "group_location" {}

variable "group_name" {}










