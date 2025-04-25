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
      "echo 'Installing AWS Agents...'",
      "sudo yum install -y -q amazon-ssm-agent amazon-cloudwatch-agent",
      "sudo systemctl enable amazon-ssm-agent",
      "sudo systemctl start amazon-ssm-agent",
      "sudo systemctl enable amazon-cloudwatch-agent",
      "sudo systemctl start amazon-cloudwatch-agent",
      "echo 'AWS Agents installed successfully.'",
      "echo 'Configuring CloudWatch Agent...'",
      "sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc",
      "cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json\n" +
      "{\n" +
      "  \"metrics\": {\n" +
      "    \"append_dimensions\": {\n" +
      "      \"AutoScalingGroupName\": \"\\$${aws:AutoScalingGroupName}\",\n" +
      "      \"InstanceId\": \"\\$${aws:InstanceId}\",\n" +
      "      \"InstanceType\": \"\\$${aws:InstanceType}\",\n" +
      "      \"ImageId\": \"\\$${aws:ImageId}\"\n" +
      "    },\n" +
      "    \"metrics_collected\": {\n" +
      "      \"cpu\": {\n" +
      "        \"measurement\": [\"cpu_usage_idle\", \"cpu_usage_iowait\", \"cpu_usage_user\", \"cpu_usage_system\"],\n" +
      "        \"metrics_collection_interval\": 60\n" +
      "      },\n" +
      "      \"mem\": {\n" +
      "        \"measurement\": [\"mem_used_percent\"],\n" +
      "        \"metrics_collection_interval\": 60\n" +
      "      }\n" +
      "    }\n" +
      "  }\n" +
      "}\n" +
      "EOF",
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
