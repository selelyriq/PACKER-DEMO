source "amazon-ebs" "aws-addons" {
  source_ami      = var.base_ami_id
  region          = var.aws_region
  instance_type   = "t3.micro"
  ssh_username    = "ec2-user"
  ami_name        = "informatica-aws-with-tools-{{timestamp}}"
}

build {
    name    = "aws-addons"
    sources = ["source.amazon-ebs.aws-addons"]

        provisioner "file" {
        source      = "scripts/setup-cloudwatch-agent.sh"
        destination = "/tmp/setup-cloudwatch-agent.sh"
    }

    provisioner "shell" {
        inline = [
        "chmod +x /tmp/setup-cloudwatch-agent.sh",
        "sudo /tmp/setup-cloudwatch-agent.sh"
        ]
    }

    provisioner "file" {
        source      = "scripts/cloudwatch-configuration.sh"
        destination = "/tmp/cloudwatch-configuration.sh"
    }

    provisioner "shell" {
        inline = [
        "chmod +x /tmp/cloudwatch-configuration.sh",
        "sudo /tmp/cloudwatch-configuration.sh"
        ]
    }
}    