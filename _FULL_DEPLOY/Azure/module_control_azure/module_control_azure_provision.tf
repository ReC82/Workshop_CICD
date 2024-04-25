##################################
# COPY THE GIT KEY
##################################
resource "null_resource" "git_key_to_controller" {
  provisioner "file" {
    source      = var.git_private_key
    destination = "/home/${var.root_user_name}/.ssh/${var.git_private_key}"
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pubip_controller.ip_address
      user        = var.root_user_name
      private_key = var.root_user_private_key
    }
  }

 provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/${var.root_user_name}/.ssh/${basename(var.git_private_key)}"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pubip_controller.ip_address
      user        = var.root_user_name
      private_key = var.root_user_private_key
    }
  }
}

##################################
# COPY THE GIT GLOBAL KEY
##################################
resource "null_resource" "git_global_key_to_controller" {
  provisioner "file" {
    source      = var.git_global_private_key
    destination = "/home/${var.root_user_name}/.ssh/${var.git_global_private_key}"
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pubip_controller.ip_address
      user        = var.root_user_name
      private_key = var.root_user_private_key
    }
  }

 provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/${var.root_user_name}/.ssh/${basename(var.git_global_private_key)}"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pubip_controller.ip_address
      user        = var.root_user_name
      private_key = var.root_user_private_key
    }
  }
}


