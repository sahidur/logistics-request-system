#!/bin/bash

# SSL Auto-Setup Script for tiktok.somadhanhobe.com
echo "🔒 Setting up SSL for tiktok.somadhanhobe.com"
echo "============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOMAIN="tiktok.somadhanhobe.com"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

echo -e "${YELLOW}Step 1: Installing Certbot...${NC}"
apt update
apt install -y certbot python3-certbot-nginx

echo -e "${YELLOW}Step 2: Checking DNS configuration...${NC}"
# Check if domain resolves to this server
DOMAIN_IP=$(dig +short $DOMAIN)
SERVER_IP=$(curl -s http://checkip.amazonaws.com/)

echo "Domain IP: $DOMAIN_IP"
echo "Server IP: $SERVER_IP"

if [ "$DOMAIN_IP" != "$SERVER_IP" ]; then
    echo -e "${YELLOW}⚠️  Warning: Domain IP ($DOMAIN_IP) doesn't match server IP ($SERVER_IP)${NC}"
    echo -e "${YELLOW}   Make sure your DNS is properly configured before continuing.${NC}"
    echo -e "${YELLOW}   Continue anyway? (y/N):${NC}"
    read -r continue_setup
    if [[ ! $continue_setup =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 1
    fi
fi

echo -e "${YELLOW}Step 3: Testing Nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Nginx configuration error. Please fix before setting up SSL.${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 4: Getting SSL certificate...${NC}"
# Get SSL certificate
certbot --nginx \
    -d $DOMAIN \
    -d www.$DOMAIN \
    --non-interactive \
    --agree-tos \
    --email admin@$DOMAIN \
    --redirect

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate successfully installed!${NC}"
    
    echo -e "${YELLOW}Step 5: Testing SSL configuration...${NC}"
    nginx -t && systemctl reload nginx
    
    echo -e "${YELLOW}Step 6: Testing auto-renewal...${NC}"
    certbot renew --dry-run
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSL auto-renewal is working!${NC}"
    else
        echo -e "${YELLOW}⚠️  SSL auto-renewal test failed, but certificate is installed${NC}"
    fi
    
    echo -e "${GREEN}🎉 SSL setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}🌐 Your site is now available at:${NC}"
    echo -e "✅ ${GREEN}https://$DOMAIN${NC}"
    echo -e "✅ ${GREEN}https://www.$DOMAIN${NC}"
    echo -e "✅ ${GREEN}https://$DOMAIN/admin${NC}"
    echo ""
    echo -e "${YELLOW}🔒 Certificate will auto-renew before expiration${NC}"
    
else
    echo -e "${RED}❌ SSL certificate installation failed!${NC}"
    echo -e "${YELLOW}Please check:${NC}"
    echo "1. Domain DNS is pointing to this server"
    echo "2. Ports 80 and 443 are open"
    echo "3. No other web server is running"
    echo "4. Domain is accessible from the internet"
    exit 1
fi
