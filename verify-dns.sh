#!/bin/bash

# 🔍 DNS Verification Script for TikTok Workshop

echo "🌐 Checking DNS Resolution for tiktok.somadhanhobe.com"
echo "=================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_IP="146.190.106.123"
DOMAIN="tiktok.somadhanhobe.com"

echo -e "${YELLOW}Expected IP: $TARGET_IP${NC}"
echo -e "${YELLOW}Checking domain: $DOMAIN${NC}"
echo ""

# Check DNS resolution
echo "🔍 DNS Lookup Results:"
RESOLVED_IP=$(nslookup $DOMAIN | grep "Address:" | tail -1 | awk '{print $2}')

if [ "$RESOLVED_IP" = "$TARGET_IP" ]; then
    echo -e "${GREEN}✅ DNS is correct: $RESOLVED_IP${NC}"
else
    echo -e "${RED}❌ DNS is wrong: $RESOLVED_IP${NC}"
    echo -e "${RED}   Should be: $TARGET_IP${NC}"
fi

echo ""

# Check website accessibility
echo "🌐 Website Accessibility Test:"

# Test via IP
if curl -s --connect-timeout 5 http://$TARGET_IP > /dev/null; then
    echo -e "${GREEN}✅ Website accessible via IP: http://$TARGET_IP${NC}"
else
    echo -e "${RED}❌ Website not accessible via IP: http://$TARGET_IP${NC}"
fi

# Test via domain
if curl -s --connect-timeout 5 http://$DOMAIN > /dev/null; then
    echo -e "${GREEN}✅ Website accessible via domain: http://$DOMAIN${NC}"
else
    echo -e "${RED}❌ Website not accessible via domain: http://$DOMAIN${NC}"
fi

echo ""

# Provide next steps
if [ "$RESOLVED_IP" != "$TARGET_IP" ]; then
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Update DNS A record for 'tiktok' to point to $TARGET_IP"
    echo "2. Wait 5-60 minutes for DNS propagation"
    echo "3. Run this script again to verify"
    echo ""
    echo -e "${YELLOW}💡 Temporary workaround:${NC}"
    echo "Access your website directly via IP: http://$TARGET_IP"
else
    echo -e "${GREEN}🎉 Everything looks good!${NC}"
    echo "Your domain is properly configured and pointing to the correct server."
fi
