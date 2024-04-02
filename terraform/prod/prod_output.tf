output "controller_public_ip" {
    value = module.prod_modules.controller_ip
}

output "private_ips" {
    value = module.prod_modules.private_ip_addresses
}

output "webapp_public_ip" {
    value = module.prod_modules.webapp_ip
}