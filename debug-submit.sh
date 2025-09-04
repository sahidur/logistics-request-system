#!/bin/bash

# 🔍 Form Submission Debug Script
# Helps diagnose "Unexpected token '<'" JSON errors

echo "🔍 Form Submission Error Diagnostic"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="146.190.106.123"
DOMAIN="tiktok.somadhanhobe.com"

echo -e "${BLUE}📋 Step 1: Test API Endpoints${NC}"
echo "============================"

# Test backend is running
echo "Testing backend server..."
if curl -s --connect-timeout 5 http://localhost:4000/health > /dev/null; then
    echo -e "${GREEN}✅ Backend responding on localhost:4000${NC}"
    
    # Get health response
    HEALTH_RESPONSE=$(curl -s http://localhost:4000/health)
    echo "   Response: $HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Backend not responding on localhost:4000${NC}"
    echo "   Try: pm2 restart tik-workshop-backend"
fi

echo ""
echo "Testing API health endpoint..."
if curl -s --connect-timeout 5 http://localhost:4000/api/health > /dev/null; then
    echo -e "${GREEN}✅ API health endpoint responding${NC}"
    
    API_HEALTH_RESPONSE=$(curl -s http://localhost:4000/api/health)
    echo "   Response: $API_HEALTH_RESPONSE"
else
    echo -e "${RED}❌ API health endpoint not responding${NC}"
fi

echo ""
echo -e "${BLUE}📋 Step 2: Test Form Submission Endpoint${NC}"
echo "========================================"

# Test POST to /api/requests with sample data
echo "Testing POST /api/requests endpoint..."
SUBMIT_RESPONSE=$(curl -s -X POST http://localhost:4000/api/requests \
  -H "Content-Type: multipart/form-data" \
  -F "name=Test User" \
  -F "email=test@example.com" \
  -F "teamName=Test Team" \
  -F 'items=[{"name":"Test Item","description":"Test Description","quantity":"1","price":"10.00","source":"Test Source"}]' \
  2>&1)

if echo "$SUBMIT_RESPONSE" | grep -q "error\|id"; then
    echo -e "${GREEN}✅ Submit endpoint responding (JSON)${NC}"
    echo "   Response: $SUBMIT_RESPONSE" | head -c 200
else
    echo -e "${RED}❌ Submit endpoint returning HTML or error${NC}"
    echo "   Response: $SUBMIT_RESPONSE" | head -c 200
    echo ""
    echo -e "${YELLOW}This is likely the cause of your 'Unexpected token' error!${NC}"
fi

echo ""
echo -e "${BLUE}📋 Step 3: Test External Access${NC}"
echo "==============================="

# Test via server IP
echo "Testing via server IP (http://$SERVER_IP:4000)..."
if curl -s --connect-timeout 10 http://$SERVER_IP:4000/api/health > /dev/null; then
    echo -e "${GREEN}✅ API accessible via server IP${NC}"
else
    echo -e "${RED}❌ API not accessible via server IP${NC}"
    echo "   Check firewall: ufw status"
fi

# Test via domain
echo "Testing via domain (https://$DOMAIN)..."
if curl -s --connect-timeout 10 https://$DOMAIN/api/health > /dev/null; then
    echo -e "${GREEN}✅ API accessible via domain (HTTPS)${NC}"
else
    echo -e "${RED}❌ API not accessible via domain (HTTPS)${NC}"
    
    # Try HTTP
    if curl -s --connect-timeout 10 http://$DOMAIN/api/health > /dev/null; then
        echo -e "${YELLOW}⚠️  API accessible via HTTP but not HTTPS${NC}"
    else
        echo -e "${RED}❌ API not accessible via domain (HTTP either)${NC}"
    fi
fi

echo ""
echo -e "${BLUE}📋 Step 4: Check Nginx Configuration${NC}"
echo "==================================="

# Check nginx status
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx is running${NC}"
    
    # Check nginx configuration
    if nginx -t 2>/dev/null; then
        echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
    else
        echo -e "${RED}❌ Nginx configuration has errors${NC}"
        nginx -t
    fi
else
    echo -e "${RED}❌ Nginx is not running${NC}"
    echo "   Try: systemctl start nginx"
fi

# Check if nginx is proxying to backend
echo ""
echo "Testing nginx proxy..."
NGINX_PROXY_TEST=$(curl -s --connect-timeout 5 http://localhost/api/health 2>&1)
if echo "$NGINX_PROXY_TEST" | grep -q "TikTok Workshop\|status"; then
    echo -e "${GREEN}✅ Nginx proxy working${NC}"
else
    echo -e "${RED}❌ Nginx proxy not working${NC}"
    echo "   Response: $NGINX_PROXY_TEST" | head -c 100
fi

echo ""
echo -e "${BLUE}📋 Step 5: Check Frontend Configuration${NC}"
echo "======================================"

# Check frontend build
FRONTEND_DIR="/var/www/tik-workshop/frontend"
if [ -d "$FRONTEND_DIR/dist" ]; then
    echo -e "${GREEN}✅ Frontend build exists${NC}"
    
    # Check if config.js has correct API URL
    if [ -f "$FRONTEND_DIR/src/config.js" ]; then
        API_URL_CONFIG=$(grep "VITE_API_URL" "$FRONTEND_DIR/.env.production" 2>/dev/null || echo "Not found")
        echo "   API URL in frontend config: $API_URL_CONFIG"
    fi
else
    echo -e "${RED}❌ Frontend build missing${NC}"
    echo "   Try: cd $FRONTEND_DIR && npm run build"
fi

echo ""
echo -e "${BLUE}📋 Quick Fixes${NC}"
echo "==============="

echo -e "${YELLOW}If you're getting 'Unexpected token' errors, try:${NC}"
echo ""
echo "1. Check if API is returning HTML instead of JSON:"
echo "   curl -v http://localhost:4000/api/requests"
echo ""
echo "2. Restart backend with logs:"
echo "   cd /var/www/tik-workshop/backend"
echo "   pm2 restart tik-workshop-backend"
echo "   pm2 logs tik-workshop-backend --lines 20"
echo ""
echo "3. Test form submission manually:"
echo '   curl -X POST http://localhost:4000/api/requests \'
echo '   -H "Content-Type: multipart/form-data" \'
echo '   -F "name=Test" -F "email=test@test.com" \'
echo '   -F "teamName=Test" -F "items=[{}]"'
echo ""
echo "4. Check nginx is proxying correctly:"
echo "   curl -v http://localhost/api/health"
echo ""
echo "5. Verify frontend API URL configuration:"
echo "   grep -r 'API_URL' /var/www/tik-workshop/frontend/"
echo ""
echo -e "${BLUE}🎯 Most Common Causes:${NC}"
echo "- Backend not running (pm2 status)"
echo "- Wrong API URL in frontend (.env.production)"  
echo "- Nginx not proxying /api requests to backend"
echo "- CORS blocking the request"
echo "- API returning error page instead of JSON"
