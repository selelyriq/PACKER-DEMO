# Common Variables
variable "informatica_script_path" {
  type    = string
  default = "images/informatica_install_script_v4.sh" # Relative path from Packer working directory
}

variable "image_name_prefix" {
  type    = string
  default = "informatica-agent"
}

variable "image_version" {
  type    = string
  default = "1.0.0"
}

# Informatica Installation Variables
variable "infauser_name" {
  type    = string
  default = "infauser"
}

variable "infauser_group" {
  type    = string
  default = "infauser"
}

variable "infauser_uid" {
  type    = string
  default = "10001"
}

variable "infauser_gid" {
  type    = string
  default = "10001"
}

variable "secagent_url" {
  type        = string
  description = "URL for the Informatica secure agent installer"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
} 

variable "aws_source_ami" {
  type    = string
}