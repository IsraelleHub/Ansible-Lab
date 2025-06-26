variable "region" {
  type    = string
  default = "us-east-2"
}

variable "AZ" {
  type = string
  default = "us-east-2a"
}

variable "VPC_cidr" {
  type = string
  default = "192.168.0.0/16" 
}

variable "public_subnet_cidr" {
  type = string
  default = "192.168.1.0/24"
}  

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "project-name" {
  type    = string
  default = "jenkins-setup-aws-ec2-lab"
}

variable "sg-name" {
  type    = string
  default = "Ansible-sg"
}

variable "keypair-name" {
  type    = string
  default = "ansible-key"
}

variable "default_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "default_user_data" {
  type    = string
  default = ""
}

variable "master_user_data" {
  type    = string
  default = "install.sh"
}

variable "amazon_ami" {
  type    = string
  default = "amazon"
}

variable "ubuntu_ami" {
  type    = string
  default = "ubuntu"
}

variable "master_name" {
  type    = string
  default = "master-instance"
}

variable "node1_name" {
  type    = string
  default = "node1-instance"
}

variable "node2_name" {
  type    = string
  default = "node2-instance"
}