#!/bin/bash
# Install Ansible and AWS-related tools on Amazon Linux 2023

# Update system packages
sudo dnf update -y

# Install Python 3 and pip (Python 3 is usually preinstalled, but pip might not be)
sudo dnf install -y python3 python3-pip
python3 -m pip install --upgrade pip

# Install Ansible via pip
sudo pip3 install ansible

# Install boto3, botocore, and AWS CLI
sudo pip3 install boto3 botocore awscli

# Install the amazon.aws Ansible collection
ansible-galaxy collection install amazon.aws

# Change terminal color for ec2-user
echo "PS1='\e[1;32m\u@\h \w$ \e[m'" >> /home/ec2-user/.bash_profile