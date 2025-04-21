# Common Variables
variable "informatica_script_path" {
  type    = string
  default = "scripts/informatica_install.sh"
}

variable "image_name_prefix" {
  type        = string
  description = "Prefix for the AMI name"
  default     = "informatica"
}

variable "image_version" {
  type        = string
  description = "Version of the AMI"
  default     = "1.0.0"
}

# Informatica Installation Variables
variable "infauser_name" {
  type        = string
  description = "Informatica user name"
  default     = "infauser"
}

variable "infauser_group" {
  type        = string
  description = "Informatica user group"
  default     = "infauser"
}

variable "infauser_gid" {
  type        = string
  description = "Informatica user group ID"
  default     = "1001"
}

variable "infauser_uid" {
  type        = string
  description = "Informatica user ID"
  default     = "1001"
}

# AWS-specific variables
variable "aws_region" {
  type        = string
  description = "AWS region to build the AMI in"
  default     = "us-east-2"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type to use for building the AMI"
  default     = "t4g.medium"
}

variable "base_ami_id" {
  type        = string
  description = "Base AMI ID to use for building the addons AMI"
  default     = ""
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
} 