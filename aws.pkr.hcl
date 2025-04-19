# Required Plugins
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
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

# Source block for AWS
source "amazon-ebs" "informatica" {
  region        = var.aws_region
  instance_type = var.instance_type
  ami_name      = "${var.image_name_prefix}-aws-${var.image_version}-${local.timestamp}"
  source_ami    = "ami-04985531f48a27ae7"
  ssh_username  = "ec2-user"

  tags = {
    Name        = "${var.image_name_prefix}-aws"
    Version     = var.image_version
    Environment = "production"
    Builder     = "packer"
  }
}

# Build block for AWS
build {
  name    = "informatica-aws"
  sources = ["source.amazon-ebs.informatica"]

  # Upload and prepare the Informatica install script
  provisioner "file" {
    source      = "images/informatica_install_script_v4.sh"
    destination = "/tmp/informatica_install.sh"
  }

  # Set up environment variables for the install script
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /images",
      "sudo mv /tmp/informatica_install.sh /images/informatica_install_script_v4.sh",
      "sudo chmod +x /images/informatica_install_script_v4.sh",
      "ls -la /images/informatica_install_script_v4.sh"  # Debug: verify file exists
    ]
  }

  # Set up environment variables
  provisioner "shell" {
    inline = [
      "echo 'export infauseruname=${var.infauser_name}' | sudo tee -a /tmp/informatica_env.sh",
      "echo 'export infausergname=${var.infauser_group}' | sudo tee -a /tmp/informatica_env.sh",
      "echo 'export infausergid=${var.infauser_gid}' | sudo tee -a /tmp/informatica_env.sh",
      "echo 'export infauseruid=${var.infauser_uid}' | sudo tee -a /tmp/informatica_env.sh",
      "echo 'export secagenturl=${var.secagent_url}' | sudo tee -a /tmp/informatica_env.sh",
      "sudo chmod +x /tmp/informatica_env.sh"
    ]
  }

  # Run the Informatica install script
  provisioner "shell" {
    inline = [
      "source /tmp/informatica_env.sh",
      "cd /images",
      "sudo -E ./informatica_install_script_v4.sh"
    ]
  }

  # Install AWS-specific tools
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y amazon-cloudwatch-agent",
      "sudo yum install -y amazon-ssm-agent",
      "sudo systemctl enable amazon-ssm-agent",
      "sudo systemctl start amazon-ssm-agent",
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:/AmazonCloudWatch-Config"
    ]
  }
}

