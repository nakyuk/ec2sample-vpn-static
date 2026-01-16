# AWS Site-to-Site VPN (Static) - EC2 Configuration

> **⚠️ DISCLAIMER: FOR TESTING PURPOSES ONLY**
> 
> This configuration is intended for **testing and development environments only** and is **NOT suitable for production use**. 
> 
> **Important considerations:**
> - No high availability or redundancy configuration
> - Single point of failure (single EC2 instance)
> - No automated failover mechanisms
> - Security configurations may need hardening for production
> - Performance tuning required for production workloads
> - No monitoring or alerting setup included
> - Simplified VPN configuration for testing only
> 
> For production deployments, consult AWS Well-Architected Framework and implement proper redundancy, monitoring, security controls, and operational procedures.

This guide demonstrates how to configure an EC2 instance as a Customer Gateway for AWS Site-to-Site VPN with static routing for testing purposes.

## Prerequisites

- AWS Account with appropriate permissions
- VPC with appropriate subnets
- Virtual Private Gateway attached to VPC
- Customer Gateway created
- Site-to-Site VPN Connection configured with static routing
- Ubuntu 22.04 AMI
- AWS CLI configured (optional, for automated setup)

## Step 1: Launch EC2 Instance

1. Launch an Ubuntu 22.04 instance with the following specifications:

- Disable Source/Destination Check
- Assign Elastic IP address
- Ensure appropriate security group rules for IPsec (UDP 500, UDP 4500, ESP protocol 50)

2. Configure Site-to-Site VPN Connection

- Create Customer Gateway with EC2's Elastic IP
- Create VPN Connection with static routing
- Configure static routes in route table

## Step 2: Configure EC2 Instance

Download VPN configuration from AWS Console and configure the EC2 instance accordingly.

```bash
#!/bin/bash
sleep 30
sudo apt update
sudo apt upgrade -y
sudo apt install -y strongswan
wget https://github.com/nakyuk/ec2sample-vpn-static/archive/refs/heads/main.zip
unzip main.zip
cd ec2sample-vpn-static-main/
sudo bash setup.sh
```

## Step 3: Verify VPN Connection

Check VPN tunnel status:

```bash
sudo strongswan status
```

Verify connectivity from AWS Console:
- Navigate to VPC > Site-to-Site VPN Connections
- Check tunnel status (should show "UP")

## Troubleshooting

- Check security group rules allow IPsec traffic
- Verify Source/Destination Check is disabled
- Review strongswan logs: `sudo journalctl -u strongswan`
- Confirm static routes are properly configured
