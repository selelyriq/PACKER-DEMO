# Modular Packer AMI Builder

This Packer configuration provides a flexible and modular approach to building Golden AMIs for AWS. It's designed to be hands-off and easily customizable through variables and custom installation scripts.

## Features

- Modular design that supports any custom installation script
- Automatic detection of the latest base RHEL AMI (configurable for other OS types)
- Comprehensive AMI tagging including base image tracking
- Built-in logging and validation
- Manifest generation for tracking builds

## Directory Structure

```
packer/
├── aws.pkr.hcl         # AWS-specific Packer configuration
├── variables.pkr.hcl    # Variable definitions
├── scripts/            # Default scripts directory
│   ├── hello_world.sh  # Example script
│   └── ... (your custom scripts)
└── README.md
```

The `scripts/` directory is maintained for:
- Example scripts and templates
- Common utility scripts shared between builds
- Default installation scripts
- Organization of project-specific scripts

While you can provide installation scripts from any location using the `custom_install_script` variable, storing your organization's scripts in the `scripts/` directory is recommended for better maintainability.

## Usage

1. Prepare your custom installation script (either in `scripts/` or any other location)
2. Set required variables
3. Run Packer build

### Basic Example

```bash
# Using a script from the scripts directory
packer build -var "custom_install_script=scripts/hello_world.sh" .

# Using a script from any location
packer build -var "custom_install_script=/path/to/your/script.sh" .
```

### Advanced Usage with Multiple Variables

```bash
packer build \
  -var "custom_install_script=/path/to/your/script.sh" \
  -var "environment=staging" \
  -var "image_version=2.0.0" \
  -var "base_image_name=ubuntu-20.04" \
  -var "base_image_owner=self" \
  .
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `custom_install_script` | Path to your installation script | Required |
| `image_name_prefix` | Prefix for the AMI name | hello_world |
| `image_version` | Version of the AMI | 1.0.0 |
| `environment` | Target environment | production |
| `aws_region` | AWS region for the build | us-east-2 |
| `instance_type` | EC2 instance type | t2.micro |
| `base_image_name` | Base AMI name pattern | rhel-9 |
| `base_image_owner` | Owner of the base image | self |

## Custom Installation Scripts

Your custom installation script should:
1. Be executable
2. Handle its own error checking
3. Exit with a non-zero status on failure

Example script structure:
```bash
#!/bin/bash
set -e

# Your installation steps here
echo "Starting installation..."

# Example: Install packages
sudo yum update -y
sudo yum install -y your-packages

# Example: Configure services
sudo systemctl enable your-service

echo "Installation complete!"
```

## Output

After a successful build, you'll find:
- A new AMI in your AWS account
- A manifest.json file with build details
- Comprehensive AMI tags for tracking

## Troubleshooting

Common issues and solutions:
1. Base AMI not found: Check `base_image_name` and `base_image_owner`
2. Script permissions: Ensure your install script is executable
3. Build failures: Check the Packer logs and your script's error handling 