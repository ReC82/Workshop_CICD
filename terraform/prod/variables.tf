variable "environment" {
  description = "Work envirronement"
  default     = "prod"
}

variable "env_space_cidr" {
  description = "Address Space Prod Env"
  default     = ["10.0.0.0/16"]
}

variable "env_subnet_space_cidr" {
  description = "Address Space Subnet Prod Env"
  default     = ["10.0.1.0/24"]
}

variable "root_user_name" {
  default = "rooty"
}

variable "root_user_password" {
  default = "P@ssw0rd!123"
}

variable "group_name" {
  description = "Production"
  default     = "production_group"
}

variable "group_location" {
  default = "centralus"
}

variable "node_count" {
  default = 3
}

variable "node_names" {
  description = "Map of node names"
  type        = map(string)
  default = {
    0 = "web"
    1 = "database"
    2 = "api"
  }
}

variable "security_groups" {
  description = "Map of Security Groups"
  type        = map(string)
  default = {
    0 = "web"
    1 = "database"
    2 = "control"
  }
}

