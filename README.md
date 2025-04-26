# Modular AMI Builder

A flexible infrastructure-as-code solution for building Golden AMIs across cloud platforms using HashiCorp Packer.

## Features

- Automated AMI building through GitHub Actions workflow
- Pre-installed AWS SSM and CloudWatch agents
- Customizable through installation scripts
- Supports custom AMI naming and versioning
- Based on Red Hat Enterprise Linux (RHEL) 9

## Quick Start

1. Fork this repository
2. Navigate to Actions tab in GitHub
3. Run the "Build Multi-Cloud Images" workflow with your custom parameters
4. Deploy your new AMI to your infrastructure

## Documentation

For detailed usage instructions, parameters, and examples, see the [Packer documentation](packer/README.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
