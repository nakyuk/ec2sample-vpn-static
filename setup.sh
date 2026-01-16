#!/bin/bash

# AWS Site-to-Site VPN Setup Script for Ubuntu 22.04
# This script configures strongSwan for static VPN connection

set -e

echo "Starting VPN setup..."

# Install strongSwan
echo "Installing strongSwan..."
apt update
apt install -y strongswan strongswan-pki libcharon-extra-plugins

# Enable IP forwarding
echo "Enabling IP forwarding..."
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Disable source/destination check (informational - must be done via AWS Console/CLI)
echo "Note: Ensure Source/Destination Check is disabled on this EC2 instance"

# Prompt for VPN configuration parameters
read -p "Enter VPN Tunnel 1 Outside IP Address: " TUNNEL1_IP
read -p "Enter VPN Tunnel 1 Pre-Shared Key: " TUNNEL1_PSK
read -p "Enter VPN Tunnel 1 Inside CIDR (e.g., 169.254.10.0/30): " TUNNEL1_CIDR
read -p "Enter AWS VPC CIDR (e.g., 10.0.0.0/16): " VPC_CIDR
read -p "Enter On-Premises CIDR (e.g., 192.168.0.0/24): " ONPREM_CIDR

# Extract tunnel inside IPs
TUNNEL1_CUSTOMER_IP=$(echo $TUNNEL1_CIDR | awk -F'[./]' '{print $1"."$2"."$3"."$4+1}')
TUNNEL1_VGW_IP=$(echo $TUNNEL1_CIDR | awk -F'[./]' '{print $1"."$2"."$3"."$4+2}')

# Create ipsec.conf
echo "Creating /etc/ipsec.conf..."
cat > /etc/ipsec.conf <<EOF
config setup
    charondebug="all"
    uniqueids=yes

conn %default
    ikelifetime=28800s
    keylife=3600s
    rekeymargin=3m
    keyingtries=%forever
    keyexchange=ikev1
    authby=secret
    ike=aes128-sha1-modp1024!
    esp=aes128-sha1-modp1024!
    leftsubnet=0.0.0.0/0
    rightsubnet=0.0.0.0/0
    dpddelay=10s
    dpdtimeout=30s
    dpdaction=restart

conn tunnel1
    auto=start
    left=%defaultroute
    leftid=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    right=$TUNNEL1_IP
    type=tunnel
    leftauth=psk
    rightauth=psk
EOF

# Create ipsec.secrets
echo "Creating /etc/ipsec.secrets..."
ELASTIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
cat > /etc/ipsec.secrets <<EOF
$ELASTIC_IP $TUNNEL1_IP : PSK "$TUNNEL1_PSK"
EOF

chmod 600 /etc/ipsec.secrets

# Configure routing
echo "Configuring routes..."
cat > /etc/strongswan.d/charon/route.conf <<EOF
charon {
    install_routes = yes
    install_virtual_ip = yes
}
EOF

# Restart strongSwan
echo "Restarting strongSwan..."
systemctl enable strongswan-starter
systemctl restart strongswan-starter

# Wait for tunnel to establish
echo "Waiting for VPN tunnel to establish..."
sleep 10

# Check status
echo "VPN tunnel status:"
strongswan status

echo ""
echo "Setup complete!"
echo "Check tunnel status with: sudo strongswan status"
echo "View logs with: sudo journalctl -u strongswan -f"
