resource "null_resource" "cp_playbooks" {
  provisioner "file" {
    source      = "../../ansible/app"
    destination = "/home/rooty/ansible"

    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pubip_controller.ip_address
      user        = "rooty"
      private_key = tls_private_key.ssh_key_linux_openssh.private_key_openssh
      agent       = false # Optional: disable SSH agent forwarding
    }
  }
}

resource "null_resource" "controller_provision" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get -y install ansible dos2unix git",
      #"sudo ansible-config init --disabled > /etc/ansible/ansible.cfg",
      "mkdir -p /home/rooty/.ssh",
      "echo '${tls_private_key.ssh_key_linux_openssh.private_key_openssh}' > /home/rooty/.ssh/id_rsa",
      "chmod 600 /home/rooty/.ssh/id_rsa",
      "dos2unix ip_list.txt",
      "while IFS= read -r ip; do ssh-keyscan -H $ip >> /home/rooty/.ssh/known_hosts; done < ip_list.txt",
      "ansible-playbook -i  ansible/app_ci/templates/inventory.hosts.j2 ansible/app_ci.yaml"
      #"sudo sed -i 's/^;host_key_checking=True/host_key_checking = False/' /home/rooty/ansible.cfg",
      #"sudo cp -f private_nodes.txt /etc/ansible/hosts"
    ]
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pubip_controller.ip_address
      user        = "rooty"
      private_key = tls_private_key.ssh_key_linux_openssh.private_key_openssh
    }
  }
  depends_on = [tls_private_key.ssh_key_linux_openssh, null_resource.output_private_ips, azurerm_virtual_network_peering.vnet_controller_to_prod, azurerm_virtual_network_peering.vnet_prod_to_controller]
}

resource "null_resource" "output_private_ips" {
  # This resource is just used as a placeholder to trigger the local-exec provisioner
  provisioner "local-exec" {
    command     = <<EOT
      $privateIps = "${join(",", azurerm_linux_virtual_machine.nodes.*.private_ip_address)}"
      $ip_raw="ip_list.txt"
      Remove-Item -Path $ip_raw -Force
      $privateIps.Split(",") | ForEach-Object {
          $_ | Out-file -Append $ip_raw -Encoding utf8
      }
      EOT
    interpreter = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "cp_iplist" {
  provisioner "file" {
    source      = "ip_list.txt"
    destination = "/home/rooty/ip_list.txt"
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.pubip_controller.ip_address
      user        = "rooty"
      private_key = tls_private_key.ssh_key_linux_openssh.private_key_openssh
    }
  }
  depends_on = [null_resource.output_private_ips]
}