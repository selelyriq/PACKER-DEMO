# Data source to get the base AMI
data "amazon-ami" "base" {
  filters = {
    name = "${var.image_name_prefix}-aws-${var.image_version}-*"
  }
  most_recent = true
  owners      = ["self"]
}

# Source block for AWS Addons
source "amazon-ebs" "cloudwatch-addons" {
  region        = var.aws_region
  instance_type = var.instance_type
  # Use the base AMI ID if provided, otherwise use the data source
  source_ami    = var.base_ami_id != "" ? var.base_ami_id : data.amazon-ami.base.id
  ami_name      = "${var.image_name_prefix}-aws-cloudwatch-${var.image_version}-${local.timestamp}"
  ssh_username  = "ec2-user"

  # Add SSH settings
  ssh_timeout = "5m"
  ssh_interface = "public_ip"

  tags = {
    Name        = "${var.image_name_prefix}-aws-cloudwatch"
    Version     = var.image_version
    Environment = "production"
    Builder     = "packer"
  }
}

# Build block for AWS Addons
build {
  name    = "cloudwatch-aws-addons"
  sources = ["source.amazon-ebs.cloudwatch-addons"]

  # Install additional AWS tools and configurations
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y amazon-cloudwatch-agent",
      "sudo yum install -y amazon-ssm-agent",
      "sudo systemctl enable amazon-ssm-agent",
      "sudo systemctl start amazon-ssm-agent",
      "echo 'CloudWatch Agent installed. Config fetch will happen at runtime.'"
    ]
  }
} 