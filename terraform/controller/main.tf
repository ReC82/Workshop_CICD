####################
# CONTROLLER ON AWS
####################
################################################
# VPC - CONTROLLER
################################################
resource "aws_vpc" "vnet_controller" {
  cidr_block       = var.env_space_cidr_vnet_controller
  instance_tenancy = "default"

  tags = {
    Name = "Controller"
  }
}
################################################
# SUBNET - CONTROLLER
################################################
resource "aws_subnet" "subnet_prod" {
  vpc_id            = aws_vpc.vnet_prod.id
  cidr_block        = var.env_subnet_space_cidr_controller
  availability_zone = var.group_location

  tags = {
    Name = "subnet_controller_internal"
  }
}
################################################
# NIC - CONTROLLER
################################################
resource "aws_network_interface" "nic_controller" {

  subnet_id = aws_subnet.subnet_prod.id

  tags = {
    Name = "nic_controller"
  }
}
################################################
# INSTANCE - CONTROLLER
################################################
resource "aws_instance" "nodecontroller" {
  ami                         = var.aws_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_prod_controller.id
  associate_public_ip_address = true
  key_name                    = "priv.pem"

  tags = {
    Env = "Controller"
  }
}

########################################################
# CONTROLLER - SECURITY GROUP
########################################################
resource "aws_security_group" "prod_security_group_controller" {
  name        = "security_group_controller"
  vpc_id      = aws_vpc.vnet_prod_controller.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    env = "Controller"
  }
}

# Create a peering between AWS and Azure