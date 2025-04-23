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

  # Upload and prepare the hello world script
  provisioner "file" {
    source      = "../scripts/hello_world.sh"
    destination = "/tmp/hello_world.sh"
  }

  # Set up environment variables for the install script
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /images",
      "sudo mv /tmp/hello_world.sh /images/hello_world.sh",
      "sudo chmod +x /images/hello_world.sh"
    ]
  }

  # Run the hello world script
  provisioner "shell" {
    inline = [
      "sudo -E /images/hello_world.sh"
    ]
  }
}
