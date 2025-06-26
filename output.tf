
output "ssh_commands" {
  value = {
    for name, instance_config in local.instance_configurations :
    name => join("", [
      "ssh -i ${var.keypair-name}.pem ",
      instance_config.ami != "" ?
        (instance_config.ami == "debian" ? "admin@" :
         instance_config.ami == "ubuntu" ? "ubuntu@" : "ec2-user@") :
        "ec2-user@",
      aws_instance.ansible_nodes[name].public_dns
    ])
  }
}


output "public-ips" {
  value = { for k, instance in aws_instance.ansible_nodes : k => instance.public_ip

  }

}

output "private-ips" {
  value = { for k, instance in aws_instance.ansible_nodes : k => instance.private_ip

  }

}