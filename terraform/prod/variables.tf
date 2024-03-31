variable "infra_environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "azure" # or aws
}