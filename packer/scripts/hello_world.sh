#!/bin/bash
set -e

echo "Starting hello world installation script..."

# Update system packages
sudo yum update -y

# Print some system information
echo "System Information:"
uname -a
cat /etc/os-release

echo "Hello World installation script completed successfully!"
exit 0