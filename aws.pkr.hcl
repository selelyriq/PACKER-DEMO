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

  # Upload the install script
  provisioner "file" {
    source      = "informatica_install.sh"
    destination = "/tmp/informatica_install.sh"
  }

  # Move, set permissions, and verify everything
  provisioner "shell" {
    inline = [
      # Confirm the file landed in /tmp
      "echo '[DEBUG] Checking /tmp after upload...'",
      "ls -la /tmp/informatica_install.sh || echo '[ERROR] Script missing in /tmp'",

      # Create /images directory if not present
      "echo '[DEBUG] Creating /images directory...'",
      "sudo mkdir -p /images",

      # Move the file and make it executable
      "echo '[DEBUG] Moving script to /images...'",
      "sudo mv /tmp/informatica_install.sh /images/informatica_install.sh || echo '[ERROR] Move failed'",

      # Permissions and visibility
      "echo '[DEBUG] Making script executable...'",
      "sudo chmod +x /images/informatica_install.sh",

      "echo '[DEBUG] Final check of /images...'",
      "ls -la /images/informatica_install.sh || echo '[ERROR] Script missing in /images after move'"
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
      "echo '[DEBUG] Contents of /images before execution:'",
      "ls -la /images || echo '[ERROR] /images missing or unreadable'",

      "echo '[DEBUG] File type:'",
      "file /images/informatica_install.sh || echo '[ERROR] File not found or invalid'",

      "echo '[DEBUG] File contents head:'",
      "head -n 5 /images/informatica_install.sh || echo '[ERROR] Could not read script'",

      "echo '[DEBUG] Executing script now...'",
      "sudo -E /images/informatica_install.sh || echo '[ERROR] Execution failed'"
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
      # Note: Deferring CloudWatch config fetch to runtime to avoid credential issues during image build
      # This can be handled using cloud-init or a systemd service on instance boot
      "echo 'CloudWatch Agent installed. Config fetch will happen at runtime.'"
    ]
  }
}
