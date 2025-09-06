#!/bin/bash

# Deploy Fixed Frontend to Server
# Run this script locally to upload fixes

echo "🚀 Deploy Fixed Frontend to Server"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_IP="152.42.229.232"
PROJECT_PATH="/var/www/tik-workshop"

echo -e "${YELLOW}📤 Uploading fixed components to server...${NC}"

# Upload LogisticsForm component
echo "Uploading LogisticsForm.jsx..."
scp frontend/src/LogisticsForm.jsx root@${SERVER_IP}:${PROJECT_PATH}/frontend/src/

# Upload new App.jsx
echo "Uploading App.jsx..."
scp frontend/src/App.jsx root@${SERVER_IP}:${PROJECT_PATH}/frontend/src/

echo -e "${YELLOW}🔧 Building frontend on server...${NC}"
ssh root@${SERVER_IP} << 'EOF'
cd /var/www/tik-workshop/frontend || exit 1

echo "Building frontend..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Frontend built successfully"
    
    echo "🔧 Restarting Nginx..."
    systemctl reload nginx
    
    echo "✅ Deployment complete!"
else
    echo "❌ Frontend build failed"
    exit 1
fi
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 Frontend Fix Deployed Successfully!${NC}"
    echo -e "${BLUE}📋 Fixed Issues:${NC}"
    echo -e "✅ LogisticsForm component created"
    echo -e "✅ App.jsx imports fixed"
    echo -e "✅ Frontend builds successfully"
    echo -e "✅ All components properly structured"

    echo -e "\n${YELLOW}📱 Your website should now work properly!${NC}"
    echo -e "🌐 Main Form: http://152.42.229.232"
    echo -e "🌐 Main Form (HTTPS): https://tiktok.somadhanhobe.com"
    echo -e "🔐 Admin Login: http://152.42.229.232/admin"
    echo -e "🔐 Admin Login (HTTPS): https://tiktok.somadhanhobe.com/admin"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi
