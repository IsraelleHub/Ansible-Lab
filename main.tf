# Master Node (Ubuntu)
resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id  # Changed from amazon_linux
  instance_type          = var.node-instance_type
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  tags = {
    Name = "ansible-master-ubuntu"  # Updated tag
  }
   connection {
    type        = "ssh"
    user        = "ubuntu"  # Ubuntu's default user
    private_key = tls_private_key.ansible_key.private_key_pem
    host        = self.public_ip
    timeout     = "5m"
  }
  provisioner "file" {
    source      = "${local_file.ssh_key.filename}"
    destination = "ansible-key.pem"  # Adjust path as needed
  }

  # Ubuntu-specific provisioning
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y python3 python3-pip git",
      "sudo pip3 install ansible",
      "sudo snap install --classic code",# Optional: Install VS Code directly
      "chmod 400 ${var.keypair_name}.pem",

    # Create ansible user with secure practices
    "sudo useradd -m ansible -s /bin/bash",
    "sudo usermod -aG sudo ansible",
    
    # Set up authorized_keys instead of copying .pem
    "sudo mkdir -p /home/ansible/.ssh",
    "sudo cp .ssh/authorized_keys /home/ansible/.ssh/",
    "sudo chown -R ansible:ansible /home/ansible/.ssh",
    "sudo chmod 700 /home/ansible/.ssh",
    "sudo chmod 600 /home/ansible/.ssh/authorized_keys",
    
    # Customize prompt
    "echo \"PS1='\\[\\e[1;32m\\]\\u@\\h \\w\\$ \\[\\e[m\\]'\" | sudo tee -a /home/ansible/.bashrc",
      
    ]
  }
}

# Node 1 (Ubuntu)
resource "aws_instance" "node1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.node-instance_type
  key_name               = aws_key_pair.ansible_key.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  
  tags = {
     Name = "ansible-node-ubuntu" 
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ansible_key.private_key_pem
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = ["sudo apt update -y", "sudo apt install -y python3"]
  }
}

# Node 2 (Debian)
resource "aws_instance" "node2" {
  ami                    = data.aws_ami.amazon_linux2.id  # Changed from amazon_linux
  instance_type          = var.node-instance_type
  key_name               = aws_key_pair.ansible_key.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  
  tags = { 
    Name = "ansible-amazon" 
  }

}