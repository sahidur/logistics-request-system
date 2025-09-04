#!/bin/bash

# Deployment Verification Script
echo "🔍 TikTok Workshop - Deployment Verification"
echo "============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="tiktok.somadhanhobe.com"
API_PORT="4000"

echo -e "${YELLOW}🌐 Testing deployment...${NC}"

# Test main website
echo -e "\n${BLUE}1. Testing main website:${NC}"
if curl -f -s -o /dev/null "http://$DOMAIN"; then
    echo -e "   ${GREEN}✅ Main site: http://$DOMAIN${NC}"
else
    echo -e "   ${RED}❌ Main site failed: http://$DOMAIN${NC}"
fi

# Test admin route
echo -e "\n${BLUE}2. Testing admin route:${NC}"
if curl -f -s "http://$DOMAIN/admin" | grep -q "TikTok\|Admin\|html"; then
    echo -e "   ${GREEN}✅ Admin route: http://$DOMAIN/admin${NC}"
else
    echo -e "   ${RED}❌ Admin route failed: http://$DOMAIN/admin${NC}"
fi

# Test API health
echo -e "\n${BLUE}3. Testing API health:${NC}"
if curl -f -s "http://$DOMAIN/health" | grep -q "healthy\|ok"; then
    echo -e "   ${GREEN}✅ API health: http://$DOMAIN/health${NC}"
else
    echo -e "   ${RED}❌ API health failed: http://$DOMAIN/health${NC}"
fi

# Test direct API port
echo -e "\n${BLUE}4. Testing direct API:${NC}"
if curl -f -s "http://$DOMAIN:$API_PORT/health" | grep -q "healthy\|ok"; then
    echo -e "   ${GREEN}✅ Direct API: http://$DOMAIN:$API_PORT/health${NC}"
else
    echo -e "   ${RED}❌ Direct API failed: http://$DOMAIN:$API_PORT/health${NC}"
fi

# Check services
echo -e "\n${BLUE}5. Checking services:${NC}"
if systemctl is-active --quiet nginx; then
    echo -e "   ${GREEN}✅ Nginx is running${NC}"
else
    echo -e "   ${RED}❌ Nginx is not running${NC}"
fi

if pgrep -f "node.*index.js" > /dev/null; then
    echo -e "   ${GREEN}✅ Node.js backend is running${NC}"
else
    echo -e "   ${RED}❌ Node.js backend is not running${NC}"
fi

echo -e "\n${GREEN}🎉 Verification complete!${NC}"
echo -e "\n${BLUE}📋 Your URLs:${NC}"
echo -e "🌐 Main site: ${GREEN}http://$DOMAIN${NC}"
echo -e "👤 Admin panel: ${GREEN}http://$DOMAIN/admin${NC}"
echo -e "🔧 API health: ${GREEN}http://$DOMAIN/health${NC}"
echo -e "\n${BLUE}🔑 Admin Login:${NC}"
echo -e "Email: ${YELLOW}admin@logistics.com${NC}"
echo -e "Password: ${YELLOW}TikTok_Admin_2025_Server_148!${NC}"
