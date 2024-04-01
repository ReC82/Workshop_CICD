# Configure the Azure provider
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
terraform {

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # https://developer.hashicorp.com/terraform/language/expressions/version-constraints
      version = "3.95.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }

  #https://developer.hashicorp.com/terraform/language/settings
  required_version = ">= 1.1.0"
}