# AWS Gateway Load Balancer Target EC2

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
> - Simplified GENEVE tunnel handling for testing only
> 
> For production deployments, consult AWS Well-Architected Framework and implement proper redundancy, monitoring, security controls, and operational procedures.

This guide demonstrates how to set up an EC2 instance as a Gateway Load Balancer (GWLB) target for testing purposes. The instance handles GENEVE encapsulated traffic and provides basic health check functionality.

## Prerequisites

- AWS Account with appropriate permissions
- VPC with subnets in multiple availability zones
- Gateway Load Balancer configured
- Amazon Linux 2023 AMI
- AWS CLI configured (optional, for automated setup)

## Step 1: Launch EC2 Instance

1. Launch an Amazon Linux 2023 instance with the following specifications:

- Enable "Allow tags in instance metadata"
- Ensure the following network connectivity between GWLB via GENEVE (UDP 6081) and health check (TCP 80)

2. Configure Gateway Load Balancer

- Create Target Group
- Register Target
- Create GWLB

3. Add the following tags to your EC2 instance with the GWLB endpoint IPs:

| Key | Example | Description |
|-----|-------|-------------|
| `GWLB_IP_A` | `10.0.1.100` | GWLB endpoint IP in AZ-A |
| `GWLB_IP_C` | `10.0.3.100` | GWLB endpoint IP in AZ-C |
| `GWLB_IP_D` | `10.0.4.100` | GWLB endpoint IP in AZ-D |

```bash
GWLB_NAME="gwy/example/abcdefg012345678"
INSTANCE_ID="i-01234567890123456"

ENI_IPS=$(aws ec2 describe-network-interfaces \
    --filters "Name=description,Values=ELB*$GWLB_NAME*" \
    --query 'NetworkInterfaces[*].[AvailabilityZone,PrivateIpAddress]' \
    --output text | sort)
IPS=($(echo "$ENI_IPS" | awk '{print $2}'))
GWLB_IP_A=${IPS[0]}
GWLB_IP_B=${IPS[1]}
GWLB_IP_C=${IPS[2]}
GWLB_IP_D=${IPS[3]}

aws ec2 create-tags \
    --resources $INSTANCE_ID \
    --tags \
        Key=GWLB_IP_A,Value=$GWLB_IP_A \
        Key=GWLB_IP_B,Value=$GWLB_IP_B \
        Key=GWLB_IP_C,Value=$GWLB_IP_C \
        Key=GWLB_IP_D,Value=$GWLB_IP_D
```

**Note:** Adjust the tag keys and values based on your GWLB endpoint configuration and availability zones.

## Step 2: Configure EC2 Instance

Run the following command on the EC2 instance

```bash
#!/bin/bash
sleep 30
sudo dnf -y upgrade --releasever=latest
sudo dnf -y update
wget https://github.com/nakyuk/ec2sample-gwlb-target/archive/refs/heads/main.zip
unzip main.zip
cd ec2sample-gwlb-target-main/
sudo bash setup.sh
```


