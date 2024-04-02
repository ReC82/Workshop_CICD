variable "environment" {
  description = "Work envirronement"
  default     = "ci"
}

variable "env_space_cidr_nodes" {
  description = "Address Space CI Env"
  default     = ["10.0.0.0/16"]
}

variable "env_subnet_space_cidr_nodes" {
  description = "Address Space Subnet CI Env"
  default     = ["10.0.1.0/24"]
}

variable "env_space_cidr_control" {
  description = "Address Space Control CI Env"
  default     = ["10.1.0.0/16"]
}

variable "env_subnet_space_cidr_control" {
  description = "Address Space Subnet CI Env"
  default     = ["10.1.1.0/24"]
}

variable "root_user_name" {
  default = "rooty"
}

variable "root_user_password" {
  default = "P@ssw0rd!123"
}

variable "group_name" {
  description = "Integration"
  default     = "ci_group"
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

