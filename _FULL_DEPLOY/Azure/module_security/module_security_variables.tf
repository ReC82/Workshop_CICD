variable "base_directory" {
  default = "keys/"
}

variable "private_key_filename" {
}

variable "public_key_filename" {
}

variable "keyname" {
  type = string
}

variable "create_new" {
  default = false
}
