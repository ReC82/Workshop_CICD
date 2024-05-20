output "controller_public_ip_prod" {
  value = module.control_modules.controller_ip
}

output "controller_public_dns" {
  value = module.control_modules.controller_dns
}

output "quality_controller_dns" {
  value = module.quality_control_modules.quality_controller_dns
}

output "private_ip_addresses" {
  value = module.prod_modules.private_ip_addresses
}

output "private_ip_addresses_mapping" {
  value = module.prod_modules.private_ip_addresses_mapping
}

output "private_ips_prod" {
  value = module.prod_modules.prod_private_ips
}

output "private_ips_agents" {
  value = module.agents_creation.private_ip_addresses
}

output "webapp_public_ip_prod" {
  value = module.prod_modules.webapp_ip
}

output "web_dns" {
  value = module.prod_modules.web_dns
}

/*
output "test" {
  value = module.prod_modules.all_nics_ids
}*/

/*
output "controller_public_ip_ci" {
  value = module.ci_modules.controller_ip
}

output "private_ips_ci" {
  value = module.ci_modules.private_ip_addresses
}

output "webapp_public_ip_ci" {
  value = module.ci_modules.webapp_ip
}
*/
