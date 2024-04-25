##########################
# GLOBAL VARIABLES
##########################

variable "group_location" {
  default = "centralus"
}

variable "group_name" {
  description = "Global Resource Group"
  default     = "EhealthResourceGroup"
}

##########################
# GLOBAL RESOURCES
##########################

resource "azurerm_resource_group" "EhealthResourceGroup" {
  name     = var.group_name
  location = var.group_location
}

##########################
# GLOBAL SSH KEY
##########################

module "global_security" {
  source               = "./module_security"
  private_key_filename = "global_infra.pem"
  public_key_filename  = "global_infra.pub"
  create_new           = true
}

##########################
# CONTROL ENVIRONMENT
##########################

module "control_security" {
  source               = "./module_security"
  private_key_filename = "control_key.pem"
  public_key_filename  = "control_key.pub"
  create_new           = true
}

module "control_modules" {
  source                 = "./module_control_azure"
  root_user_name         = var.root_user_name
  root_user_password     = var.root_user_password
  group_location         = var.group_location
  group_name             = var.group_name
  root_user_public_key   = module.control_security.public_key_content
  root_user_private_key  = module.control_security.private_key_content
  git_private_key        = pathexpand("git.pem")
  git_global_private_key = pathexpand("git_global_key")
  depends_on = [
    azurerm_resource_group.EhealthResourceGroup,
    module.control_security
  ]
}

module "control_provision" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script      = pathexpand("./scripts/controller/control_provision.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Install requirements for the controller device"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.global_security
  ]
}

#############################################
# CLONE ANSIBLE FILES
#############################################

module "control_git_clone_ansible_files" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["${var.root_user_name}", "git_global_key"]
  script      = pathexpand("./scripts/controller/control_git_clone.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Clone Ansible Files on the Controller"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.control_provision
  ]
}

#############################
# QUALITY CONTROL ENVIRONMENT
#############################

module "quality_control_modules" {
  source                 = "./module_quality_control"
  root_user_name         = var.root_user_name
  root_user_password     = var.root_user_password
  group_location         = var.group_location
  group_name             = var.group_name
  control_vnet_name      = module.control_modules.control_vnet_name
  root_user_public_key   = module.control_security.public_key_content
  root_user_private_key  = module.control_security.private_key_content
  git_private_key        = pathexpand("git.pem")
  git_global_private_key = pathexpand("git_global_key")
  depends_on = [
    azurerm_resource_group.EhealthResourceGroup,
    module.control_security,
    module.control_modules
  ]
}

module "control_add_qc_private_key" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"${module.control_security.private_key_content}\""]
  script      = pathexpand("./scripts/controller/control_add_quality_control_key.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Add Quality Key To Control"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.agents_creation,
    module.agents_access_security
  ]
}

##########################
# PRODUCTION ENVIRONMENT
##########################

module "production_security" {
  source               = "./module_security"
  private_key_filename = "production_key.pem"
  public_key_filename  = "production_key.pub"
  create_new           = true
}

module "prod_modules" {
  source                             = "./module_create_environment"
  resource_group_name                = var.group_name
  resource_location                  = var.group_location
  controller_ip                      = module.control_modules.controller_ip
  environment_name                   = "Production"
  environment_vnet_addr_space_suffix = "10.10.0.0/16"
  node_count                         = 3
  nodes_configuration = [
    {
      node_name = "web"
      subnet    = ["10.10.1.0/24"]
      count     = 1
    },
    {
      node_name = "database"
      subnet    = ["10.10.2.0/24"]
      count     = 1
    },
    {
      node_name = "api"
      subnet    = ["10.10.3.0/24"]
      count     = 1
    }
  ]
  root_user_name        = var.root_user_name
  root_user_password    = var.root_user_password
  root_user_private_key = module.production_security.private_key_content
  root_user_public_key  = module.production_security.public_key_content
  depends_on = [
    module.control_modules,
    module.production_security,
    azurerm_resource_group.EhealthResourceGroup
  ]
}

#############################################
# PEERING CONTROL => PROD && PROD => CONTROL
#############################################

module "peering_control_prod" {
  source              = "./module_peering"
  vnet_source_name    = module.control_modules.control_vnet_name
  vnet_destination_id = module.prod_modules.vnet_id
  peering_group_name  = var.group_name
  peering_name        = "Peering_Control_to_Prod"
  depends_on = [
    module.control_modules,
    module.prod_modules
  ]
}

module "peering_prod_control" {
  source              = "./module_peering"
  vnet_source_name    = module.prod_modules.vnet_name
  vnet_destination_id = module.control_modules.control_vnet_id
  peering_group_name  = var.group_name
  peering_name        = "Peering_Control_to_Prod"
  depends_on = [
    module.control_modules,
    module.prod_modules
  ]
}

###############################################
# ADD PROD TO CONTROL TRUSTED IPS
###############################################

module "control_add_prod_ips_to_known_hosts" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"${module.prod_modules.private_ip_addresses}\""]
  script      = pathexpand("./scripts/controller/control_add_trusted_ips.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Add Prod Module IPS to control known_host file"
  depends_on = [
    module.control_modules,
    module.control_provision,
    module.control_security,
    module.prod_modules,
    module.peering_control_prod,
    module.peering_prod_control
  ]
}

###############################################
# ADD QUALITY CONTROL TO CONTROL TRUSTED IPS
###############################################

module "control_add_qc_ips_to_known_hosts" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"${module.quality_control_modules.quality_controller_priv_addrr}\""]
  script      = pathexpand("./scripts/controller/control_add_trusted_ips.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Add QC IP to control known_host file"
  depends_on = [
    module.control_modules,
    module.control_provision,
    module.control_security,
    module.prod_modules,
    module.peering_control_prod,
    module.peering_prod_control
  ]
}

###################################################
# AGENTS CREATION
###################################################

module "agents_access_security" {
  source               = "./module_security"
  private_key_filename = "agents_key.pem"
  public_key_filename  = "agents_key.pub"
  create_new           = true
}

module "agents_creation" {
  source                = "./module_agents"
  controller_vnet_name  = module.control_modules.control_vnet_name
  root_user_name        = var.root_user_name
  root_user_password    = var.root_user_password
  root_user_private_key = module.agents_access_security.private_key_content
  root_user_public_key  = module.agents_access_security.public_key_content
  group_location        = var.group_location
  group_name            = var.group_name
  controller_public_key = module.control_security.public_key_content
  environment_name      = "Agents"
  agents_count          = 2
  depends_on = [
    azurerm_resource_group.EhealthResourceGroup,
    module.agents_access_security,
    module.control_modules,
    module.control_security
  ]
}

module "control_add_agents_private_key" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"${module.agents_access_security.private_key_content}\""]
  script      = pathexpand("./scripts/controller/control_add_agents_key.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Add Agents Key To Control"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.agents_creation,
    module.agents_access_security
  ]
}

##########################################
# ANSIBLE INVENTORY FILE : AGENTS 
##########################################

module "generate_agent_inventory_file" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"${module.agents_creation.private_ip_addresses_mapping}\""]
  script      = pathexpand("./scripts/controller/control_build_agent_inv_files.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Create Agent Inv"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.agents_creation,
    module.agents_access_security
  ]
}

##########################################
# ANSIBLE INVENTORY FILE : QC 
##########################################

module "generate_qc_inventory_file" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"${module.quality_control_modules.quality_controller_priv_addrr}\" \"quality_control\""]
  script      = pathexpand("./scripts/controller/control_build_inventory_files.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Create QC Inv"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.agents_creation,
    module.agents_access_security
  ]
}

###############################################
# ADD AGENTS TO CONTROL TRUSTED IPS
###############################################

module "control_add_agents_ips_to_known_hosts" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"${module.agents_creation.private_ip_addresses}\""]
  script      = pathexpand("./scripts/controller/control_add_trusted_ips.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content

  description = "Add Agents Module IPS to control known_host file"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.agents_creation,
    module.control_provision,
    module.peering_control_prod,
    module.peering_prod_control
  ]
}

##################################################"
# RUN PLAYBOOK ON AGENTS
##################################################"

module "start_ansible_on_agents" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"agents\"", "agent.pem"]
  script      = pathexpand("./scripts/controller/control_ansible_play.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Create Agent Inv"
  depends_on = [
    module.control_modules,
    module.control_add_agents_ips_to_known_hosts,
    module.control_git_clone_ansible_files,
    module.control_security,
    module.agents_creation,
    module.agents_access_security
  ]
}

##################################################"
# RUN PLAYBOOK ON QUALITY CONTROL
##################################################"

module "start_ansible_on_qc" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = ["\"quality_control\"", "qc.pem"]
  script      = pathexpand("./scripts/controller/control_ansible_play.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Create Agent Inv"
  depends_on = [
    module.control_modules,
    module.control_add_agents_ips_to_known_hosts,
    module.control_git_clone_ansible_files,
    module.control_security,
    module.agents_creation,
    module.agents_access_security
  ]
}

################################################
# CREATE JENKINS BACKUP - RESTORE SCRIPT
################################################
module "create_jenkins_backup_restore_scripts" {
  count       = 1
  source      = "./module_provisionner"
  destination = module.control_modules.controller_ip
  script_args = [""]
  script      = pathexpand("./scripts/controller/control_create_backup_restore_scripts.sh")
  username    = var.root_user_name
  private_key = module.control_security.private_key_content
  description = "Create Jenkins Backup and Restore scripts"
  depends_on = [
    module.control_modules,
    module.control_security,
    module.prod_modules,
    module.peering_control_prod,
    module.peering_prod_control,
    module.control_provision
  ]
}