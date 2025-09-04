#!/bin/bash

# SSL Auto-Setup Script for tiecho -e "${YELLOW}Step 4: Checking and configuring firewall...${NC}"
# Ensure ports are open
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "Firewall status:"
ufw status verbose

echo -e "${YELLOW}Step 5: Checking for port conflicts...${NC}"
# Check what's using port 80 and 443
echo "Services using port 80:"
lsof -i :80 || echo "Port 80 is free"
echo "Services using port 443:"  
lsof -i :443 || echo "Port 443 is free"

# Stop conflicting services
if systemctl is-active --quiet apache2; then
    echo "Stopping Apache2..."
    systemctl stop apache2
    systemctl disable apache2
fitok.somadhanhobe.com
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

echo -e "${YELLOW}Step 6: Testing Nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Nginx configuration error. Please fix before setting up SSL.${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 7: Getting SSL certificate using standalone mode...${NC}"
# Stop nginx temporarily for standalone mode
systemctl stop nginx

# Get SSL certificate using standalone mode (more reliable)
certbot certonly --standalone \
    -d $DOMAIN \
    -d www.$DOMAIN \
    --non-interactive \
    --agree-tos \
    --email admin@$DOMAIN \
    --preferred-challenges http

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSL certificate obtained!${NC}"
    
    # Start nginx again
    systemctl start nginx
    sleep 2
    
    # Now configure nginx to use the certificate
    echo -e "${YELLOW}Step 8: Configuring Nginx for SSL...${NC}"
    certbot --nginx \
        -d $DOMAIN \
        -d www.$DOMAIN \
        --non-interactive \
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
