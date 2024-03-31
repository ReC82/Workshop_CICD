# Define a map to map each environment value to its corresponding module sources
locals {
  module_sources = {
    "azure" = {
      module_prod_azure = "./module_prod_azure"
    }
    "aws" = {
      module_prod_aws = "./module_prod_aws"
    }
    "default" = {
      module_prod_default = "./module_prod_azure"
    }
  }
}

locals {
  modules_list = [
    for module_name, module_source in local.module_sources[infra_environment] : {
      name   = module_name
      source = module_source
    }
  ]
}

# Import modules based on infra_environment
module "azure_modules" {
  source = local.modules_list[*].source
}
