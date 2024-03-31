# Define a map to map each environment value to its corresponding module sources
locals {
  module_sources = {
    "azure" = {
      module1 = "./module_prod_azure"
      # Add more modules as needed
    }
    "aws" = {
      module1 = "./module_prod_aws"
      # Add more modules as needed
    }
    "default" = {
      module1 = "./module_prod_azure"
      # Add more modules as needed
    }
  }
}

# Define a list of objects representing modules
locals {
  modules_list = [
    for module_name, module_source in local.module_sources[infra_environment] : {
      name   = module_name
      source = module_source
    }
  ]
}

# Import modules based on the value of the environment variable
module "azure_modules" {
  source = local.modules_list[*].source
}
