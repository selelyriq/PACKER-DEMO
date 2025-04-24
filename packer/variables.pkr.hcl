# Common Variables
variable "hello_world_script_path" {
  type    = string
  default = "scripts/hello_world.sh"
}

variable "image_name_prefix" {
  type        = string
  description = "Prefix for the AMI name"
  default     = "hello_world"
}

variable "image_version" {
  type        = string
  description = "Version of the AMI"
  default     = "1.0.0"
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
  default     = "t2.large"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# Azure-specific variables

variable "resource_group_name" {
  type        = string
  description = "Resource group name to use for building the AMI"
  default     = "Work_Testing"
}

variable "location" {
  type        = string
  description = "Azure location to build the AMI in"
  default     = "eastus"
}

variable "vm_size" {
  type        = string
  description = "Azure VM size to use for building the AMI"
  default     = "Standard_D2s_v3"
}