# Common Variables
variable "informatica_script_path" {
  type    = string
  default = "scripts/informatica_install.sh"
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

# AWS-specific variables
variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "base_ami_id" {
  type        = string
  description = "The base AMI ID to use for the addons build"
  default     = "" # This will be set by the pipeline
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
} 