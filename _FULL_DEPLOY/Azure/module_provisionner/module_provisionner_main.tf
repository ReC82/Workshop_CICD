# COPY THE SCRIPT TO THE DESTINATION
resource "null_resource" "script_copy" {

  provisioner "file" {
    source      = "${var.script}"
    destination = "${var.remote_tmp_folder}/${basename(var.script)}"
    connection {
      type        = "ssh"
      host        = var.destination
      user        = var.username
      private_key = var.private_key
    }
  }
}
# EXECUTE THE SCRIPT ON THE DESTINATION
resource "null_resource" "script_execution" {

  provisioner "remote-exec" {
    inline = [
      "chmod +x ${var.remote_tmp_folder}/${basename(var.script)}",
      "${var.remote_tmp_folder}/${basename(var.script)} ${join(" ", var.script_args)}"
    ]
    connection {
      type        = "ssh"
      host        = var.destination
      user        = var.username
      private_key = var.private_key
    }
  }
  depends_on = [ null_resource.script_copy ]
}