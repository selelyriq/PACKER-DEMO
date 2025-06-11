# Common Variables
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

variable "environment" {
  type        = string
  description = "Environment (e.g., 'production')"
  default     = "production"
}

variable "custom_ami_name" {
  type        = string
  description = "Custom name for the AMI (will be appended with timestamp)"
  default     = null  # If null, will use the default naming pattern
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
  default     = "t2.micro"
}

variable "ssh_username" {
  type        = string
  description = "SSH username for the AMI"
  default     = "ec2-user"
}

variable "custom_install_script" {
  type        = string
  description = "Path to a custom install script to inject into the AMI"
  default     = "scripts/hello_world.sh"
}

variable "base_image_name" {
  type        = string
  description = "Base name prefix of the image to search for (e.g., 'rhel-9')"
  default     = "RHEL-9.2.0_HVM-*"
}

variable "base_image_owner" {
  type        = string
  description = "Owner of the base image (Red Hat's AWS account ID)"
  default     = "137112412989 "  # Red Hat's AWS account ID
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  ami_name = var.custom_ami_name != null ? "${var.custom_ami_name}-${var.environment}-${var.image_version}-${local.timestamp}" : "${var.image_name_prefix}-${var.environment}-${var.image_version}-${local.timestamp}"
}
