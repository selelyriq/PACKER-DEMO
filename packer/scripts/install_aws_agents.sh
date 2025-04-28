#!/bin/bash
set -e

echo "Downloading and installing AWS SSM Agent..."
curl -L -o /tmp/ssm-agent.rpm https://s3.us-east-2.amazonaws.com/amazon-ssm-us-east-2/latest/linux_amd64/amazon-ssm-agent.rpm
sudo yum install -y /tmp/ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

echo "Downloading and installing AWS CloudWatch Agent..."
curl -L -o /tmp/amazon-cloudwatch-agent.rpm https://s3.us-east-2.amazonaws.com/amazoncloudwatch-agent-us-east-2/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo yum install -y /tmp/amazon-cloudwatch-agent.rpm
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent

echo "AWS Agents installed successfully."

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:/cloudwatch-agent/config -s
echo "CloudWatch Agent fetched config from SSM and started."