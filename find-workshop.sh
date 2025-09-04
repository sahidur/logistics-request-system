#!/bin/bash

# Find TikTok Workshop Directory Script
echo "🔍 Finding TikTok Workshop Directory"
echo "===================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Common locations where the project might be
POSSIBLE_LOCATIONS=(
    "/opt/tik-workshop"
    "/tmp/tik-workshop" 
    "/root/tik-workshop"
    "/home/*/tik-workshop"
    "/var/www/tik-workshop"
    "$(pwd)/tik-workshop"
)

echo -e "${YELLOW}Searching for TikTok Workshop directory...${NC}"

FOUND_LOCATIONS=()

for location in "${POSSIBLE_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        if [ -f "$location/package.json" ] || [ -f "$location/deploy-app.sh" ]; then
            FOUND_LOCATIONS+=("$location")
        fi
    fi
done

# Also search for any directory containing our project files
echo -e "${YELLOW}Searching system-wide for logistics-request-system...${NC}"
SEARCH_RESULTS=$(find / -name "logistics-request-system" -type d 2>/dev/null | head -5)

if [ ${#FOUND_LOCATIONS[@]} -eq 0 ] && [ -z "$SEARCH_RESULTS" ]; then
    echo -e "${YELLOW}❌ No existing TikTok Workshop directory found.${NC}"
    echo ""
    echo -e "${BLUE}📁 RECOMMENDED: Clone to a permanent location:${NC}"
    echo "git clone https://github.com/sahidur/logistics-request-system.git /opt/tik-workshop"
    echo "cd /opt/tik-workshop"
    echo ""
    echo -e "${BLUE}🚀 Then run deployment:${NC}"
    echo "chmod +x *.sh"
    echo "sudo ./deploy-app.sh"
    
else
    echo -e "${GREEN}✅ Found TikTok Workshop directories:${NC}"
    echo ""
    
    # Show found locations
    for location in "${FOUND_LOCATIONS[@]}"; do
        echo -e "${GREEN}📁 $location${NC}"
        if [ -f "$location/deploy-app.sh" ]; then
            echo "   ✅ Contains deployment scripts"
        fi
        if [ -f "$location/package.json" ]; then
            echo "   ✅ Contains project files"
        fi
        echo ""
    done
    
    # Show search results
    if [ ! -z "$SEARCH_RESULTS" ]; then
        echo -e "${BLUE}📋 Other possible locations:${NC}"
        echo "$SEARCH_RESULTS"
        echo ""
    fi
    
    # Show recommended location
    if [[ " ${FOUND_LOCATIONS[@]} " =~ " /opt/tik-workshop " ]]; then
        echo -e "${GREEN}🎯 RECOMMENDED: Use /opt/tik-workshop${NC}"
        echo "cd /opt/tik-workshop"
    else
        echo -e "${YELLOW}🎯 RECOMMENDED: Move to /opt/tik-workshop for consistency${NC}"
        FIRST_FOUND="${FOUND_LOCATIONS[0]}"
        echo "sudo mv '$FIRST_FOUND' /opt/tik-workshop"
        echo "cd /opt/tik-workshop"
    fi
fi

echo ""
echo -e "${BLUE}🔧 USEFUL COMMANDS:${NC}"
echo "Update code:           git pull origin main"
echo "Deploy application:    sudo ./deploy-app.sh"  
echo "Configure firewall:    sudo ./configure-firewall.sh"
echo "Setup SSL:             sudo ./setup-ssl.sh"
echo "Verify deployment:     sudo ./verify-deployment.sh"
echo "View PM2 processes:    sudo -u tikworkshop pm2 list"
echo "View logs:             sudo -u tikworkshop pm2 logs"
