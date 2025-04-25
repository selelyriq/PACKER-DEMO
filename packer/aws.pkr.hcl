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
      "sudo mv ~/custom_install.sh /opt/scripts/",
      "sudo chmod +x /opt/scripts/custom_install.sh",
      "echo 'Script preparation complete'",
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
