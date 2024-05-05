#####################
# OUTPUTS
#####################
output "private_key_filepath" {
  value = var.create_new ? local_file.export_private_key.filename : fileexists(var.private_key_filename) ? var.private_key_filename : null
}

output "public_key_filepath" {
  value = var.create_new ? local_file.export_public_key.filename : fileexists(var.public_key_filename) ? var.public_key_filename : null
}

output "private_key_content" {
  value = var.create_new ? local_file.export_private_key.content : fileexists(var.private_key_filename) ? file(var.private_key_filename) : null
}

output "public_key_content" {
  value = var.create_new ? local_file.export_public_key.content : fileexists(var.public_key_filename) ? file(var.public_key_filename) : null
}

output "keyname" {
  value = var.keyname
}

output "security_map" {
  value = {
    keyname     = var.keyname
    private_key = local_file.export_private_key.content 
    public_key  = local_file.export_public_key.content
  }
}
