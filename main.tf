# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {
}

# Create Web Security Group
resource "aws_security_group" "web-sg" {
  name        = "ansible-Web-SG1"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Windows RDP from VPC"
    from_port   = 3389
    to_port     = 3389
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

#create ec2 instances 

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 3.0"

  for_each = var.instance_configurations

  ##for_each = toset(["ansible-master", "target-node1", "target-node2"])

  name = each.value.name

  ami           = each.value.ami != "" ? (each.value.ami == "debian" ? data.aws_ami.debian.id : each.value.ami == "ubuntu" ? data.aws_ami.ubuntu.id : data.aws_ami.amazon-2.id) : data.aws_ami.amazon-2.id
  instance_type = each.value.instance_type
  key_name      = aws_key_pair.ec2_key.key_name
  #monitoring             = true
  user_data              = each.value.user_data != "" ? file("${path.module}/${each.value.user_data}") : ""
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  tags = {
    Terraform = "true"
    Env       = each.value.Env
  }
}
# here we are using the Null resource to copy our ssh key into the master server.
resource "null_resource" "copy_ssh_key" {
  depends_on = [module.ec2_instance["master"]]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.ec2_key.private_key_pem
    host        = module.ec2_instance["master"].public_ip
  }

  provisioner "file" {
    source      = "${var.keypair-name}.pem"
    destination = "/home/ec2-user/${var.keypair-name}.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      #install amazon ansible-ec2 plugin
      "ansible-galaxy collection install amazon.aws",
      # # install ansible with python3
      "sudo yum update -y",
      "sudo amazon-linux-extras install epel python3.8 -y",
      "sudo yum install git sshpass -y",
      "sudo pip3.8 install ansible",
      # #install boto3 and botocore
      "sudo pip3.8 install boto3 botocore awscli yamllint",
      #change terminal color
      "chmod 400 /home/ec2-user/${var.keypair-name}.pem",
      "sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd",
      "echo 'ec2-user:ansible' | sudo chpasswd",
    ]
  }

}
resource "local_file" "ansible_inventory" {
  filename = "ansible-dev/dev-inv.ini"
  content = var.create_windows_server ? templatefile("${path.module}/templates/inv_with_windows.tpl", {
    wind_pass = rsadecrypt(aws_instance.windows_2022[0].password_data, tls_private_key.ec2_key.private_key_pem)
    Key       = local_file.ssh_key.filename
    db_ip     = module.ec2_instance["node2"].private_ip
    ws_ip     = module.ec2_instance["node1"].private_ip
    wind_ip   = var.create_windows_server ? aws_instance.windows_2022[0].private_ip : ""
    }) : templatefile("${path.module}/templates/inv_without_windows.tpl", {
    Key   = local_file.ssh_key.filename
    db_ip = module.ec2_instance["node2"].private_ip
    ws_ip = module.ec2_instance["node1"].private_ip
  })
  depends_on = [module.ec2_instance, aws_instance.windows_2022, local_file.ssh_key]
}

resource "null_resource" "copy_inventory" {

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.ec2_key.private_key_pem
    host        = module.ec2_instance["master"].public_ip
  }
  provisioner "file" {
    source      = "${path.module}/ansible-dev"
    destination = "/home/ec2-user/ansible-dev"
  }

  depends_on = [module.ec2_instance, local_file.ansible_inventory]
}

resource "aws_instance" "windows_2022" {
  count         = var.create_windows_server ? 1 : 0
  ami           = data.aws_ami.windows_2022.id
  instance_type = var.windows_server_config.instance_type
  //subnet_id     = aws_subnet.your_existing_subnet.id
  key_name               = aws_key_pair.ec2_key.key_name
  get_password_data      = true
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = filebase64("${path.module}/windows.ps1")

  tags = {
    Name = var.windows_server_config.name
    OS   = "Windows Server 2022"
    Env  = "prod"
  }
}