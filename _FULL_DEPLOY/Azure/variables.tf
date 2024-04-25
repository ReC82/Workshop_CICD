variable "infra_environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "azure" # or aws
}

variable "root_user_name" {
  default = "rooty"
}

variable "root_user_password" {
  default = "P@ssw0rd!123"
}

