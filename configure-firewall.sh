#!/bin/bash

# Firewall and Port Configuration Script
echo "🔥 Configuring Firewall and Opening Ports for SSL"
echo "================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

echo -e "${YELLOW}Step 1: Checking current firewall status...${NC}"
ufw status verbose

echo -e "\n${YELLOW}Step 2: Checking current open ports...${NC}"
netstat -tlnp | grep -E ':80|:443|:4000'

echo -e "\n${YELLOW}Step 3: Stopping any conflicting services...${NC}"
# Stop Apache if it's running (common conflict)
if systemctl is-active --quiet apache2; then
    echo "Stopping Apache2..."
    systemctl stop apache2
    systemctl disable apache2
fi

echo -e "\n${YELLOW}Step 4: Configuring UFW firewall...${NC}"
# Reset UFW to clean state
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (CRITICAL - don't lock yourself out!)
ufw allow OpenSSH
ufw allow 22/tcp

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow our Node.js backend (optional, usually proxied through nginx)
ufw allow 4000/tcp

# Enable UFW
ufw --force enable

echo -e "\n${YELLOW}Step 5: Verifying firewall rules...${NC}"
ufw status verbose

echo -e "\n${YELLOW}Step 6: Testing port accessibility...${NC}"
# Check if ports are now accessible
echo "Testing port 80..."
nc -z localhost 80 && echo "Port 80: OPEN" || echo "Port 80: CLOSED"

echo "Testing port 443..."
nc -z localhost 443 && echo "Port 443: OPEN" || echo "Port 443: CLOSED"

echo -e "\n${YELLOW}Step 7: Restarting nginx to bind to ports...${NC}"
systemctl stop nginx
sleep 2
systemctl start nginx
systemctl enable nginx

echo -e "\n${YELLOW}Step 8: Checking nginx status and port binding...${NC}"
systemctl status nginx --no-pager -l
echo ""
netstat -tlnp | grep nginx

echo -e "\n${YELLOW}Step 9: Testing external port accessibility...${NC}"
echo "Testing from external (this might take a moment)..."
timeout 10 curl -I http://$(curl -s http://checkip.amazonaws.com/):80 2>/dev/null && echo "External port 80: ACCESSIBLE" || echo "External port 80: NOT ACCESSIBLE"

echo -e "\n${GREEN}✅ Firewall configuration completed!${NC}"
echo ""
echo -e "${BLUE}📋 SUMMARY:${NC}"
echo -e "✅ SSH (22): ${GREEN}ALLOWED${NC}"
echo -e "✅ HTTP (80): ${GREEN}ALLOWED${NC}"
echo -e "✅ HTTPS (443): ${GREEN}ALLOWED${NC}"
echo -e "✅ Backend (4000): ${GREEN}ALLOWED${NC}"
echo ""
echo -e "${YELLOW}🔒 Now you can install SSL:${NC}"
echo "sudo ./setup-ssl.sh"
echo ""
echo -e "${YELLOW}🌐 Or run full deployment:${NC}"
echo "sudo ./deploy-app.sh"

echo -e "\n${YELLOW}🛠️  TROUBLESHOOTING:${NC}"
echo "If SSL still fails, check:"
echo "1. Domain DNS points to this server IP"
echo "2. No cloud firewall blocking ports (DigitalOcean, AWS, etc.)"
echo "3. ISP not blocking ports"
echo "4. Run: sudo ufw status verbose"
