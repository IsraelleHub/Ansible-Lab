variable "region" {
  type    = string
  default = "us-east-1"
}

variable "sg-name" {
  type    = string
  default = "Ansible-sg"
}

variable "keypair-name" {
  type    = string
  default = "ansiblekey"
}

variable "instance_configurations" {
  type = map(object({
    instance_type = string
    name          = string
    user_data     = string
    ami           = string
    Env           = string
  }))


}


variable "create_windows_server" {
  description = "Whether to create the Windows instance"
  type        = bool
  default     = false
}

variable "windows_server_config" {
  description = "Windows Server configuration"
  type = object({
    name          = string
    instance_type = string
  })
  default = {
    name          = "win2022-server"
    instance_type = "t2.medium"
  }
}