# Data source to get the base AMI
data "amazon-ami" "base" {
  filters = {
    name = "${var.image_name_prefix}-aws-${var.image_version}-*"
  }
  most_recent = true
  owners      = ["self"]
}

# Source block for AWS Addons
source "amazon-ebs" "informatica-addons" {
  region        = var.aws_region
  instance_type = var.instance_type
  source_ami    = coalesce(var.base_ami_id, data.amazon-ami.base.id)
  ami_name      = "${var.image_name_prefix}-aws-addons-${var.image_version}-${local.timestamp}"
  ssh_username  = "ec2-user"

  tags = {
    Name        = "${var.image_name_prefix}-aws-addons"
    Version     = var.image_version
    Environment = "production"
    Builder     = "packer"
  }
}

# Build block for AWS Addons
build {
  name    = "informatica-aws-addons"
  sources = ["source.amazon-ebs.informatica-addons"]

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