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