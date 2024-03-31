# Create AWS resource group
resource "aws_resource_group" "prod_group" {
  name = var.group_name
}

################################################
# NODES - PRODUCTION - NETWORK
################################################
resource "aws_vpc" "vnet_prod" {
  cidr_block       = var.env_space_cidr_nodes
  instance_tenancy = "default"

  tags = {
    Name = "vnet_${var.environment}"
  }
}

resource "aws_subnet" "subnet_prod" {
  vpc_id            = aws_vpc.vnet_prod.id
  cidr_block        = var.env_space_cidr_nodes
  availability_zone = var.group_location

  tags = {
    Name = "subnet_${var.environment}_internal"
  }
}

resource "aws_network_interface" "nic_prod_nodes" {
  count = var.node_count

  subnet_id = aws_subnet.subnet_prod.id

  tags = {
    Name = "nic_${var.environment}_node_${count.index}"
  }
}

######################################
# CONTROLLER - NETWORK - PRODUCTION
######################################
resource "aws_vpc" "vnet_prod_controller" {
  cidr_block       = var.env_space_cidr_control
  instance_tenancy = "default"

  tags = {
    Name = "vnet_${var.environment}_controller"
  }
}

resource "aws_subnet" "subnet_prod_controller" {
  vpc_id            = aws_vpc.vnet_prod_controller.id
  cidr_block        = var.env_subnet_space_cidr_control
  availability_zone = var.group_location

  tags = {
    Name = "subnet_controller_${var.environment}_internal"
  }
}

resource "aws_network_interface" "nic_prod_controller" {
  subnet_id = aws_subnet.subnet_prod_controller.id

  tags = {
    Name = "nic_${var.environment}_controller"
  }
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
  content  = tls_private_key.ssh_key_linux_openssh.private_key_pem
  filename = "priv.pem"
}

resource "local_file" "export_public_key" {
  content  = tls_private_key.ssh_key_linux_openssh.public_key_openssh
  filename = "public.pub"
}

resource "aws_instance" "nodecontroller" {
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_prod_controller.id
  associate_public_ip_address = true
  key_name                    = tls_private_key.ssh_key_linux_openssh.id

  tags = {
    Name = "nodecontroller"
  }
}

resource "aws_instance" "nodes" {
  count                       = var.node_count
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_prod.id
  associate_public_ip_address = true
  key_name                    = tls_private_key.ssh_key_linux_openssh.id

  tags = {
    Name = "node-${var.node_names[count.index]}${format("%02d", count.index + 1)}"
  }
}

#########################
# NODES - SECURITY GROUP
#########################
resource "aws_security_group" "prod_security_group_nodes" {
  name        = "${var.environment}_security_group_nodes"
  vpc_id      = aws_vpc.vnet_prod.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.env_subnet_space_cidr_control[0]]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.10/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.10/32"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.11/32"]
  }

  tags = {
    env = "Production"
  }
}

# Association
resource "aws_network_interface_sg_attachment" "prod_sga_nodes" {
  for_each = aws_network_interface.nic_prod_nodes

  network_interface_id = each.value.id
  security_group_id    = aws_security_group.prod_security_group_nodes.id
}

########################################################
# CONTROLLER - SECURITY GROUP
########################################################
resource "aws_security_group" "prod_security_group_controller" {
  name        = "${var.environment}_security_group_controller"
  vpc_id      = aws_vpc.vnet_prod_controller.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    env = "Production"
  }
}

# Association
resource "aws_network_interface_sg_attachment" "prod_sga_controller" {
  network_interface_id = aws_network_interface.nic_prod_controller.id
  security_group_id    = aws_security_group.prod_security_group_controller.id
}

##########################################################
#  Peering to access nodes from Controller
##########################################################

# Peering connection from vnet_prod_controller to vnet_prod
resource "aws_vpc_peering_connection" "vnet_controller_to_prod" {
  vpc_id        = aws_vpc.vnet_prod_controller.id
  peer_vpc_id   = aws_vpc.vnet_prod.id
  peer_region   = "us-east-1"
  auto_accept   = true

  tags = {
    Name = "vnet-controller-to-prod"
  }
}

# Peering connection from vnet_prod to vnet_prod_controller
resource "aws_vpc_peering_connection" "vnet_prod_to_controller" {
  vpc_id        = aws_vpc.vnet_prod.id
  peer_vpc_id   = aws_vpc.vnet_prod_controller.id
  peer_region   = "us-east-1"
  auto_accept   = true

  tags = {
    Name = "vnet-prod-to-controller"
  }
}
