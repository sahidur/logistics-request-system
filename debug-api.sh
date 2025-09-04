#!/bin/bash

# 🔍 API Troubleshooting Script for TikTok Workshop
# Run this on your server to diagnose API issues

echo "🔍 TikTok Workshop API Diagnostic"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="146.190.106.123"
DOMAIN="tiktok.somadhanhobe.com"

echo -e "${BLUE}📋 Step 1: Check Backend Process${NC}"
echo "====================================="

# Check if backend is running
if pgrep -f "node.*index.js" > /dev/null; then
    echo -e "${GREEN}✅ Backend process is running${NC}"
    echo "   PIDs: $(pgrep -f "node.*index.js" | tr '\n' ' ')"
else
    echo -e "${RED}❌ Backend process not running${NC}"
fi

# Check PM2 status
echo ""
echo "PM2 Status:"
pm2 status 2>/dev/null || echo "PM2 not running or no processes"

echo ""
echo -e "${BLUE}📋 Step 2: Check Port 4000${NC}"
echo "=========================="

# Check if port 4000 is open
if netstat -ln | grep -q ":4000"; then
    echo -e "${GREEN}✅ Port 4000 is in use${NC}"
    echo "   Listening processes:"
    netstat -lntp | grep ":4000" | head -5
else
    echo -e "${RED}❌ Port 4000 is not in use${NC}"
fi

# Check if port is accessible locally
if curl -s --connect-timeout 5 http://localhost:4000/health > /dev/null; then
    echo -e "${GREEN}✅ Backend responding on localhost:4000${NC}"
else
    echo -e "${RED}❌ Backend not responding on localhost:4000${NC}"
fi

echo ""
echo -e "${BLUE}📋 Step 3: Test API Endpoints${NC}"
echo "==============================="

# Test health endpoint
echo "Testing /health endpoint:"
HEALTH_RESPONSE=$(curl -s --connect-timeout 5 http://localhost:4000/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ /health endpoint working${NC}"
    echo "   Response: $HEALTH_RESPONSE" | head -c 100
else
    echo -e "${RED}❌ /health endpoint failed${NC}"
fi

# Test API health endpoint
echo ""
echo "Testing /api/health endpoint:"
API_HEALTH_RESPONSE=$(curl -s --connect-timeout 5 http://localhost:4000/api/health 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ /api/health endpoint working${NC}"
    echo "   Response: $API_HEALTH_RESPONSE" | head -c 100
else
    echo -e "${RED}❌ /api/health endpoint failed${NC}"
fi

# Test root API endpoint
echo ""
echo "Testing root API endpoint:"
ROOT_RESPONSE=$(curl -s --connect-timeout 5 http://localhost:4000/ 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Root endpoint working${NC}"
    echo "   Contains API info: $(echo "$ROOT_RESPONSE" | grep -q "Logistics Request Backend API" && echo "Yes" || echo "No")"
else
    echo -e "${RED}❌ Root endpoint failed${NC}"
fi

echo ""
echo -e "${BLUE}📋 Step 4: Check Firewall & Network${NC}"
echo "====================================="

# Check UFW status
echo "UFW Firewall Status:"
ufw status 2>/dev/null | head -10 || echo "UFW not available"

# Check if external access works
echo ""
echo "Testing external access:"

# Test via server IP
if curl -s --connect-timeout 10 http://$SERVER_IP:4000/health > /dev/null; then
    echo -e "${GREEN}✅ API accessible via server IP: http://$SERVER_IP:4000${NC}"
else
    echo -e "${RED}❌ API not accessible via server IP: http://$SERVER_IP:4000${NC}"
fi

# Test via domain (if DNS is configured)
if curl -s --connect-timeout 10 http://$DOMAIN/api/health > /dev/null; then
    echo -e "${GREEN}✅ API accessible via domain: http://$DOMAIN/api${NC}"
else
    echo -e "${RED}❌ API not accessible via domain: http://$DOMAIN/api${NC}"
fi

echo ""
echo -e "${BLUE}📋 Step 5: Check Environment & Configuration${NC}"
echo "=============================================="

# Check if we're in backend directory
if [ -f "package.json" ] && [ -f "index.js" ]; then
    echo -e "${GREEN}✅ In backend directory${NC}"
    
    # Check .env file
    if [ -f ".env" ]; then
        echo -e "${GREEN}✅ .env file exists${NC}"
        
        # Check key environment variables
        if grep -q "DATABASE_URL=" .env; then
            echo -e "${GREEN}✅ DATABASE_URL configured${NC}"
        else
            echo -e "${RED}❌ DATABASE_URL missing${NC}"
        fi
        
        if grep -q "PORT=" .env; then
            PORT_VAL=$(grep "PORT=" .env | cut -d'=' -f2)
            echo -e "${GREEN}✅ PORT configured: $PORT_VAL${NC}"
        else
            echo -e "${YELLOW}⚠️  PORT not set (using default 4000)${NC}"
        fi
    else
        echo -e "${RED}❌ .env file missing${NC}"
    fi
    
    # Check node_modules
    if [ -d "node_modules" ]; then
        echo -e "${GREEN}✅ node_modules directory exists${NC}"
        
        # Check if bcrypt is installed
        if [ -d "node_modules/bcryptjs" ] || [ -d "node_modules/bcrypt" ]; then
            echo -e "${GREEN}✅ bcrypt/bcryptjs installed${NC}"
        else
            echo -e "${RED}❌ bcrypt/bcryptjs missing${NC}"
        fi
    else
        echo -e "${RED}❌ node_modules missing${NC}"
    fi
    
else
    echo -e "${RED}❌ Not in backend directory${NC}"
    echo "Please run: cd /var/www/tik-workshop/backend"
fi

echo ""
echo -e "${BLUE}📋 Step 6: Recent Logs${NC}"
echo "======================"

# PM2 logs
echo "Recent PM2 logs (if available):"
pm2 logs --lines 10 2>/dev/null | tail -20 || echo "No PM2 logs available"

echo ""
echo -e "${BLUE}📋 Quick Fixes${NC}"
echo "==============="

echo -e "${YELLOW}If API is not working, try these commands:${NC}"
echo ""
echo "1. Restart backend:"
echo "   cd /var/www/tik-workshop/backend"
echo "   pm2 delete all"
echo "   pm2 start index.js --name tik-workshop-backend"
echo ""
echo "2. Check and fix environment:"
echo "   cp ../.env.production .env"
echo "   npm install"
echo "   npx prisma generate"
echo ""
echo "3. Open firewall port:"
echo "   ufw allow 4000"
echo ""
echo "4. Test manually:"
echo "   node index.js"
echo ""
echo -e "${YELLOW}For immediate testing, try:${NC}"
echo "curl -v http://localhost:4000/health"
echo "curl -v http://localhost:4000/api/health"
echo "curl -v http://$SERVER_IP:4000/health"
