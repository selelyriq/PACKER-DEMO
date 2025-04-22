# Source block for AWS
source "amazon-ebs" "AWS_BASE" {
  region        = var.aws_region
  instance_type = var.instance_type
  ami_name      = "${var.image_name_prefix}-aws-${var.image_version}-${local.timestamp}"
  source_ami    = "ami-084b4ce2bb19cbf2a"
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
  name    = "aws-base"
  sources = ["source.amazon-ebs.AWS_BASE"]

  # Upload and prepare the Informatica install script
  provisioner "file" {
    source      = "packer/scripts/informatica_install.sh"
    destination = "/tmp/informatica_install.sh"
  }

  # Set up environment variables for the install script
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /images",
      "sudo mv /tmp/informatica_install.sh /images/informatica_install.sh",
      "sudo chmod +x /images/informatica_install.sh"
    ]
  }

  # Set up environment variables
  provisioner "shell" {
    inline = [
      "echo 'export infauseruname=${var.infauser_name}' | sudo tee -a /tmp/informatica_env.sh",
      "echo 'export infausergname=${var.infauser_group}' | sudo tee -a /tmp/informatica_env.sh",
      "echo 'export infausergid=${var.infauser_gid}' | sudo tee -a /tmp/informatica_env.sh",
      "echo 'export infauseruid=${var.infauser_uid}' | sudo tee -a /tmp/informatica_env.sh",
      "sudo chmod +x /tmp/informatica_env.sh"
    ]
  }

  # Run the Informatica install script
  provisioner "shell" {
    inline = [
      "source /tmp/informatica_env.sh",
      "sudo -E /images/informatica_install.sh"
    ]
  }
}
