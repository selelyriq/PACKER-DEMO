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

echo "Configuring CloudWatch Agent..."
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null
{
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
echo "CloudWatch Agent configured and started."