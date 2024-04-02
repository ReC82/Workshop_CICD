# Define module blocks for each environment

module "prod_modules" {
  #source = "./module_prod_aws"
  source = "./module_prod_azure"
}