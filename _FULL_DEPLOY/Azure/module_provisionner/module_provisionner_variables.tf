variable "destination" {}

variable "script" {}

variable "script_args" {
    default = [""]  
}

variable "username" {}

variable "private_key" {}

variable "description" {}

variable "remote_tmp_folder" {
    default = "/tmp"
}