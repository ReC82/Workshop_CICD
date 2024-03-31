# Define a variable with three possible values
variable "infra_environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "azure" # You can set the default value to any of the three possible values
}