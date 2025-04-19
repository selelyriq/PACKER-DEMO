# packer {
#   required_plugins {
#     azure = {
#       version = ">= 1.0.0"
#       source  = "github.com/hashicorp/azure"
#     }
#   }
# }

# # Azure-specific variables
# variable "azure_subscription_id" {
#   type = string
# }

# variable "azure_resource_group" {
#   type = string
# }

# variable "azure_location" {
#   type    = string
#   default = "eastus"
# }

# # Source block for Azure
# source "azure-arm" "informatica" {
#   subscription_id = var.azure_subscription_id

#   managed_image_resource_group_name = var.azure_resource_group
#   managed_image_name               = "${var.image_name_prefix}-azure-${var.image_version}-${local.timestamp}"

#   os_type         = "Linux"
#   image_publisher = "OpenLogic"
#   image_offer     = "CentOS"
#   image_sku       = "7_9"

#   location = var.azure_location
#   vm_size  = "Standard_D2s_v3"

#   azure_tags = {
#     Name        = "${var.image_name_prefix}-azure"
#     Version     = var.image_version
#     Environment = "production"
#     Builder     = "packer"
#   }
# }

# # Build block for Azure
# build {
#   name = "informatica-azure"
#   sources = ["source.azure-arm.informatica"]

#   # Upload and prepare the Informatica install script
#   provisioner "file" {
#     source      = var.informatica_script_path
#     destination = "/tmp/informatica_install.sh"
#   }

#   # Set up environment variables for the install script
#   provisioner "shell" {
#     inline = [
#       "chmod +x /tmp/informatica_install.sh",
#       "sudo mkdir -p /images",
#       "sudo mv /tmp/informatica_install.sh /images/informatica_install_script_v4.sh",
#       "echo 'export infauseruname=${var.infauser_name}' | sudo tee -a /tmp/informatica_env.sh",
#       "echo 'export infausergname=${var.infauser_group}' | sudo tee -a /tmp/informatica_env.sh",
#       "echo 'export infausergid=${var.infauser_gid}' | sudo tee -a /tmp/informatica_env.sh",
#       "echo 'export infauseruid=${var.infauser_uid}' | sudo tee -a /tmp/informatica_env.sh",
#       "echo 'export secagenturl=${var.secagent_url}' | sudo tee -a /tmp/informatica_env.sh",
#       "sudo chmod +x /tmp/informatica_env.sh"
#     ]
#   }

#   # Run the Informatica install script
#   provisioner "shell" {
#     inline = [
#       "source /tmp/informatica_env.sh",
#       "sudo -E /images/informatica_install_script_v4.sh"
#     ]
#   }

#   # Install Azure-specific tools
#   provisioner "shell" {
#     inline = [
#       "sudo rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm",
#       "sudo yum install -y azure-monitor-agent",
#       "sudo yum install -y azcmagent",
#       "sudo systemctl enable azure-monitor-agent",
#       "sudo systemctl start azure-monitor-agent",
#       "sudo azcmagent connect --service-principal-id '<YOUR_SP_ID>' --service-principal-secret '<YOUR_SP_SECRET>' --tenant-id '<YOUR_TENANT_ID>' --resource-group '${var.azure_resource_group}' --location '${var.azure_location}'"
#     ]
#   }
# } 