# Source block for Azure
source "azure-arm" "AZURE_BASE" {
  # Azure authentication
  client_id       = var.client_id
  subscription_id = var.subscription_id
  client_secret   = var.client_secret
  
  # Resource group and location
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = "${var.image_name_prefix}-azure-${var.image_version}-${local.timestamp}"
  location                          = var.location

  # VM Configuration
  os_type = "Linux"
  vm_size = var.vm_size

  # Use RHEL 9 image
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "9-lvm-gen2"
  image_version   = "latest"

  # Managed disk configuration
  managed_image_storage_account_type = "Premium_LRS"

  # SSH configuration
  ssh_username = "packer"
  ssh_timeout  = "20m"

  # Tags
  azure_tags = {
    Name        = "${var.image_name_prefix}-azure"
    Version     = var.image_version
    Environment = "production"
    Builder     = "packer"
  }
}

# Build block for Azure
build {
  name    = "azure-base"
  sources = ["source.azure-arm.AZURE_BASE"]

  # Upload and prepare the hello world script
  provisioner "file" {
    source      = "scripts/hello_world.sh"
    destination = "/tmp/hello_world.sh"
  }

  # Make script executable and run it
  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/hello_world.sh",
      "/tmp/hello_world.sh"
    ]
  }

  # Install Azure-specific tools
  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y WALinuxAgent",
      "sudo systemctl enable waagent",
      "sudo systemctl start waagent"
    ]
  }
}
