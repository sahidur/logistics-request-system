#!/bin/bash

# Fix Maintenance Page Issue - Deploy React App
# SSH to server and run: ./replace-maintenance-with-app.sh

echo "🔧 Replacing Maintenance Page with React App"
echo "==========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Current web directory content:${NC}"
ls -la /var/www/html/

echo -e "\n${YELLOW}📋 Checking for maintenance page...${NC}"
if [ -f "/var/www/html/index.html" ]; then
    echo -e "${YELLOW}Current index.html content:${NC}"
    head -5 /var/www/html/index.html
fi

echo -e "\n${YELLOW}🏗️ Building React application with CSS fixes...${NC}"
cd /var/www/tik-workshop/frontend || {
    echo -e "${RED}❌ Project directory not found${NC}"
    exit 1
}

# Pull latest changes with CSS fixes
echo -e "${YELLOW}📥 Pulling latest changes from repository...${NC}"
git pull origin main

# Install dependencies and build
npm install
npm run build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ React app built successfully${NC}"
    
    echo -e "${YELLOW}💾 Backing up current web content...${NC}"
    sudo cp -r /var/www/html /var/www/html.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    
    echo -e "${YELLOW}📁 Deploying React app to web directory...${NC}"
    # Remove old content and deploy new
    sudo rm -rf /var/www/html/*
    sudo cp -r dist/* /var/www/html/
    
    # Set proper permissions
    sudo chown -R www-data:www-data /var/www/html/
    sudo chmod -R 755 /var/www/html/
    
    echo -e "${YELLOW}✅ New content deployed. Checking...${NC}"
    ls -la /var/www/html/ | head -10
    
    echo -e "\n${YELLOW}📄 New index.html preview:${NC}"
    head -10 /var/www/html/index.html
    
else
    echo -e "${RED}❌ React build failed${NC}"
    echo -e "${YELLOW}Checking for errors...${NC}"
    npm run build
    exit 1
fi

echo -e "\n${YELLOW}🔄 Restarting web server...${NC}"
sudo systemctl reload nginx
sudo systemctl status nginx | head -5

echo -e "\n${YELLOW}🔍 Testing backend connection...${NC}"
curl -s http://localhost:4000/health || echo -e "${RED}Backend may not be running${NC}"

echo -e "\n${YELLOW}🔍 Checking PM2 processes...${NC}"
pm2 list | head -10

echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${BLUE}📋 What was done:${NC}"
echo -e "✅ Built fresh React application"
echo -e "✅ Removed maintenance page"
echo -e "✅ Deployed React app to /var/www/html/"
echo -e "✅ Set proper file permissions"
echo -e "✅ Reloaded nginx server"

echo -e "\n${YELLOW}🌐 Your application should now show:${NC}"
echo -e "📝 TikTok Learning Sharing Workshop - Logistics Request Form"
echo -e "🔗 http://152.42.229.232"
echo -e "🔗 https://tiktok.somadhanhobe.com"
echo -e "🔐 Admin: https://tiktok.somadhanhobe.com/admin"

echo -e "\n${YELLOW}💡 If still showing maintenance:${NC}"
echo -e "1. Clear browser cache (Ctrl+F5 or Cmd+Shift+R)"
echo -e "2. Wait 30 seconds for nginx to fully reload"
echo -e "3. Check: curl http://localhost | head -5"
echo -e "4. Restart nginx: sudo systemctl restart nginx"
