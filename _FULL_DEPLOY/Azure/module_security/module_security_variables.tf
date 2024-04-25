variable "base_directory" {
  default = "keys/"
}

variable "private_key_filename" {
  default = "infrakey.pem"
}

variable "public_key_filename" {
  default = "infrakey.pub"
}

variable "create_new" {
  default = false
}
