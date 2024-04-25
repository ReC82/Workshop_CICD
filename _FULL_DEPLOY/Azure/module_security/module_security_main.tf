locals {
  private_key_filepath = var.create_new ? "${var.base_directory}${var.private_key_filename}" : (fileexists("${var.base_directory}${var.private_key_filename}") ? "" : "${var.base_directory}${var.private_key_filename}")
  
  public_key_filepath = var.create_new ? "${var.base_directory}${var.public_key_filename}" : (fileexists("${var.base_directory}${var.public_key_filename}") ? "" : "${var.base_directory}${var.public_key_filename}")
}

#####################
# SSH KEY
#####################
resource "tls_private_key" "ssh_key_linux_openssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#####################
# SSH KEY - EXPORT
#####################
resource "local_file" "export_private_key" {
  content    = tls_private_key.ssh_key_linux_openssh.private_key_pem
  filename   = local.private_key_filepath
  depends_on = [tls_private_key.ssh_key_linux_openssh]
}

resource "local_file" "export_public_key" {
  content    = tls_private_key.ssh_key_linux_openssh.public_key_openssh
  filename   = local.public_key_filepath
  depends_on = [tls_private_key.ssh_key_linux_openssh]
}