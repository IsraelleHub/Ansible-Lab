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

variable "project-name" {
  type    = string
  default = "Ansible-lab"
}

variable "node-instance_type" {
  type    = string
  default = "t3.micro"
}

variable "sg_name" {
  type        = string
  default     = "Ansible-sg"  # From your original
  description = "Security group name tag"
}

variable "keypair_name" {
  type        = string
  default     = "ansible-key"  # From your original
  description = "Name of the AWS key pair"
}
variable "ansible_password" {
  type        = string
  default     = null  # Set via TF_VAR_ansible_password
  description = "Password for ansible user (randomly generated if null)"
  sensitive   = true
}

locals {
  ssh_user = "ubuntu"  # Or logic to detect based on AMI
}