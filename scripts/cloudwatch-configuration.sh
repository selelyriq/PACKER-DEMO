name: cloudwatch-agent-setup
description: Configures and starts the CloudWatch Agent with custom metrics
schemaVersion: 1.0
phases:
  build:
    commands:
      - |
        # Install CloudWatch Agent if not already installed
        if ! [ -x /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl ]; then
          yum install -y amazon-cloudwatch-agent
        fi

        # Create config directory
        mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

        # Write JSON config
        cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
        {
          "agent": {
            "metrics_collection_interval": 60,
            "run_as_user": "root"
          },
          "metrics": {
            "append_dimensions": {
              "InstanceId": "\${aws:InstanceId}",
              "InstanceType": "\${aws:InstanceType}"
            },
            "metrics_collected": {
              "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
              },
              "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
              },
              "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
              }
            }
          }
        }
        EOF

        # Write systemd bootstrap unit
        cat <<EOF > /etc/systemd/system/cloudwatch-agent-bootstrap.service
        [Unit]
        Description=Start and configure CloudWatch Agent after boot
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=oneshot
        ExecStart=/bin/bash -c 'while [ ! -f /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json ]; do sleep 2; done; /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s'
        RemainAfterExit=true

        [Install]
        WantedBy=multi-user.target
        EOF

        systemctl daemon-reexec
        systemctl daemon-reload
        systemctl enable cloudwatch-agent-bootstrap.service