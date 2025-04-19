#!/bin/bash
set -e

echo "Installing CloudWatch and SSM agents..."

# CloudWatch Agent
sudo yum install -y amazon-cloudwatch-agent

# Pull in config from S3 or define locally if needed
# aws s3 cp s3://your-bucket/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/

# SSM Agent
sudo yum install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

echo "CloudWatch and SSM agents installed and configured."