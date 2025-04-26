# Modular Packer AMI Builder

This Packer configuration provides a flexible and modular approach to building Golden AMIs for AWS. It's designed to be hands-off and easily customizable through variables and custom installation scripts.

## Features

- Modular design that supports any custom installation script
- Automatic detection of the latest base RHEL AMI (configurable for other OS types)
- Comprehensive AMI tagging including base image tracking
- Pre-installed AWS SSM and CloudWatch agents for systems management
- GitHub Actions workflow for automated builds
- Built-in logging and validation
- Manifest generation for tracking builds

## Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── build-images.yml  # GitHub Actions workflow configuration
├── packer/
│   ├── aws.pkr.hcl          # AWS-specific Packer configuration
│   ├── variables.pkr.hcl     # Variable definitions
│   ├── scripts/             # Default scripts directory
│   │   ├── hello_world.sh   # Example script
│   │   ├── install_aws_agents.sh # AWS agents installation script
│   │   └── ... (your custom scripts)
│   └── README.md
└── README.md
```

The `scripts/` directory is maintained for:
- Example scripts and templates
- Common utility scripts shared between builds
- Default installation scripts
- Organization of project-specific scripts

While you can provide installation scripts from any location using the `custom_install_script` variable, storing your organization's scripts in the `scripts/` directory is recommended for better maintainability.

## Usage

### GitHub Actions Workflow

The easiest way to build an AMI is using the included GitHub Actions workflow:

1. Navigate to the "Actions" tab in your repository
2. Select the "Build Multi-Cloud Images" workflow
3. Click "Run workflow"
4. Fill in the parameters:
   - Base image name (e.g., `RHEL-9.2.0_HVM-*`)
   - Custom install script path (e.g., `scripts/hello_world.sh`)
   - Environment (optional)
   - Image version (optional)
   - Custom AMI name (optional)
5. Click "Run workflow"

### Local/CLI Usage

1. Prepare your custom installation script (either in `scripts/` or any other location)
2. Set required variables
3. Run Packer build

#### Basic Example

```bash
# Using a script from the scripts directory
packer build -var "custom_install_script=scripts/hello_world.sh" packer/

# Using a script from any location
packer build -var "custom_install_script=/path/to/your/script.sh" packer/
```

#### Advanced Usage with Multiple Variables

```bash
packer build \
  -var "custom_install_script=scripts/hello_world.sh" \
  -var "environment=staging" \
  -var "image_version=2.0.0" \
  -var "base_image_name=RHEL-9.2.0_HVM-*" \
  -var "custom_ami_name=my-custom-ami" \
  packer/
```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `custom_install_script` | Path to your installation script | scripts/hello_world.sh |
| `image_name_prefix` | Prefix for the AMI name | hello_world |
| `image_version` | Version of the AMI | 1.0.0 |
| `environment` | Target environment | production |
| `custom_ami_name` | Custom name for the AMI (timestamp will be appended) | null |
| `aws_region` | AWS region for the build | us-east-2 |
| `instance_type` | EC2 instance type | t2.micro |
| `base_image_name` | Base AMI name pattern | RHEL-9.2.0_HVM-* |
| `base_image_owner` | Owner of the base image | 309956199498 (Red Hat) |

## Pre-installed Software

Each AMI built with this configuration includes:

1. **AWS SSM Agent** - For remote management and patching
2. **AWS CloudWatch Agent** - For monitoring and logging
3. **Custom software** - Installed via your provided installation script

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

## AMI Naming

AMIs are named using the following pattern regardless of whether a custom name is provided:

`{name}-{environment}-{image_version}-{timestamp}`

Where `{name}` is either:
- The custom name provided via `custom_ami_name` variable
- The default `image_name_prefix` value ("hello_world" by default)

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