# Create a VPC

resource "aws_vpc" "lab_vpc" {

  cidr_block           = var.VPC_cidr
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  instance_tenancy     = "default"

  tags = {
    Name = "${var.project-name}-VPC"
  }

}

# Create an Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_vpc.id

  tags = {
    Name = "${var.project-name}-igw"
  }
}

# Create a route table

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project-name}-public-route-table"
  }
}

# Associate the route table with the public subnet

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create a public subnet

resource "aws_subnet" "public_subnet" {

  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.AZ

  tags = {
    Name = "${var.project-name}-public-subnet"
  }
}

# Create Web Security Group
resource "aws_security_group" "web-sg" {
  name        = "ansible-Web-SG"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "http port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg-name
  }
}

# define local variables for ansible master and node

locals {
  instance_configurations = {
    master = {
      instance_type     = var.default_instance_type,
      name              = var.master_name,
      user_data         = var.master_user_data 
      ami               = var.amazon_ami,
      root_block_device = {
        volume_size           = 20
        volume_type           = "gp3"
        delete_on_termination = true
      }
    },
    node1 = {
      instance_type     = var.default_instance_type,
      name              = var.node1_name,
      user_data         = var.default_user_data 
      ami               = var.amazon_ami,
      root_block_device = null
    },
    node2 = {
      instance_type     = var.default_instance_type,
      name              = var.node2_name,
      user_data         = var.default_user_data 
      ami               = var.ubuntu_ami,
      root_block_device = null
    }
  }
}


#create ec2 instances 

resource "aws_instance" "ansible_nodes" {
  for_each = local.instance_configurations

  ami           =  each.value.ami != "" ? (each.value.ami == "debian" ? data.aws_ami.debian.id : each.value.ami == "ubuntu"   ? data.aws_ami.ubuntu.id : data.aws_ami.amazon_linux.id) : data.aws_ami.amazon_linux.id
  instance_type = each.value.instance_type
  key_name      = aws_key_pair.ec2_key.key_name
  subnet_id     = aws_subnet.public_subnet.id

  user_data = each.value.user_data != "" ? file("${path.module}/${each.value.user_data}") : null

  vpc_security_group_ids = [aws_security_group.web-sg.id]

  tags = {
    Name        = each.value.name
    Terraform   = "true"
    Environment = each.key
  }

  dynamic "root_block_device" {
    for_each = each.value.root_block_device != null ? [each.value.root_block_device] : []
    content {
      volume_size           = root_block_device.value.volume_size
      volume_type           = root_block_device.value.volume_type
      delete_on_termination = root_block_device.value.delete_on_termination
    }
  }
}

# here we are using the Null resource to copy our ssh key into the master server.
resource "null_resource" "copy_ssh_key" {
  depends_on = [aws_instance.ansible_nodes["master"]]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.ec2_key.private_key_pem
    host        = aws_instance.ansible_nodes["master"].public_ip
  }

  provisioner "file" {
    source      = "${var.keypair-name}.pem"
    destination = "/home/ec2-user/${var.keypair-name}.pem"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y python3 python3-pip",
      "python3 -m pip install --upgrade pip",
      "sudo pip3 install ansible",
      "ansible-galaxy collection install amazon.aws",
      "sudo pip3 install boto3 botocore awscli",
      "echo \"PS1='\\e[1;32m\\u@\\h \\w$ \\e[m'\" >> /home/ec2-user/.bash_profile"
    ]
  }
}