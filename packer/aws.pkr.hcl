# AWS AMI Builder Configuration

# Find the latest base AMI
data "amazon-ami" "base" {
  most_recent = true
  owners      = [var.base_image_owner]

  filters = {
    name                = "${var.base_image_name}*"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
    state              = "available"
  }
}

# Base AWS Builder Configuration
source "amazon-ebs" "base" {
  region          = var.aws_region
  instance_type   = var.instance_type
  ami_name        = local.ami_name
  source_ami      = data.amazon-ami.base.id
  ssh_username    = var.ssh_username
  ami_description = "Golden AMI built with Packer for ${var.environment}"

  tags = {
    Name          = local.ami_name
    Version       = var.image_version
    Environment   = var.environment
    Builder       = "packer"
    BaseImageId   = "{{ .SourceAMI }}"
    BaseImageName = "{{ .SourceAMIName }}"
  }

  dynamic "tag" {
    for_each = data.amazon-ami.base.tags
    content {
      key   = "Base_${tag.key}"
      value = tag.value
    }
  }
}

# Build Configuration
build {
  name    = "aws-base"
  sources = ["source.amazon-ebs.base"]

  # Upload the custom install script
  provisioner "file" {
    source      = "${path.root}/${var.custom_install_script}"
    destination = "/tmp/custom_install.sh"
  }

  # Prepare the environment
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/scripts",
      "sudo mv /tmp/custom_install.sh /opt/scripts/",
      "sudo chmod +x /opt/scripts/custom_install.sh",
      "echo 'Script preparation complete'",
    ]
  }

  # Install and configure AWS SSM and CloudWatch Agents before custom install
  provisioner "shell" {
    inline = [
      "echo 'Downloading and installing AWS SSM Agent...'",
      "curl -L -o /tmp/ssm-agent.rpm https://s3.us-east-2.amazonaws.com/amazon-ssm-us-east-2/latest/linux_amd64/amazon-ssm-agent.rpm",
      "sudo yum install -y /tmp/ssm-agent.rpm",
      "sudo systemctl enable amazon-ssm-agent",
      "sudo systemctl start amazon-ssm-agent",

      "echo 'Downloading and installing AWS CloudWatch Agent...'",
      "curl -L -o /tmp/amazon-cloudwatch-agent.rpm https://s3.us-east-2.amazonaws.com/amazoncloudwatch-agent-us-east-2/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm",
      "sudo yum install -y /tmp/amazon-cloudwatch-agent.rpm",
      "sudo systemctl enable amazon-cloudwatch-agent",
      "sudo systemctl start amazon-cloudwatch-agent",
      "echo 'AWS Agents installed successfully.'",
      "echo 'Configuring CloudWatch Agent...'",
      "sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
      <<-EOT
      cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
      {
        "metrics": {
          "append_dimensions": {
            "AutoScalingGroupName": "\\$${aws:AutoScalingGroupName}",
            "InstanceId": "\\$${aws:InstanceId}",
            "InstanceType": "\\$${aws:InstanceType}",
            "ImageId": "\\$${aws:ImageId}"
          },
          "metrics_collected": {
            "cpu": {
              "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
              "metrics_collection_interval": 60
            },
            "mem": {
              "measurement": ["mem_used_percent"],
              "metrics_collection_interval": 60
            }
          }
        }
      }
      EOF
      EOT
      ,
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s",
      "echo 'CloudWatch Agent configured and started.'"
    ]
  }

  # Execute the custom install script
  provisioner "shell" {
    inline = [
      "echo 'Starting custom installation...'",
      "sudo -E /opt/scripts/custom_install.sh",
      "echo 'Custom installation complete'",
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "sudo rm -rf /opt/scripts",
      "echo 'Cleanup complete'",
    ]
  }

  # Post-processor for validation
  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}
