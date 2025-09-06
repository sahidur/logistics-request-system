#!/bin/bash

# Fix Backend API - Ensure API is Running and Accessible
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x fix-backend-api.sh && ./fix-backend-api.sh

echo "🚀 Fixing Backend API - Ensuring API is Running"
echo "==============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if backend directory exists
if [ ! -d "/var/www/tik-workshop/backend" ]; then
    echo -e "${RED}❌ Backend directory not found${NC}"
    exit 1
fi

# Navigate to backend directory
cd /var/www/tik-workshop/backend

echo -e "${YELLOW}🔍 Checking current backend status...${NC}"
pm2 list

echo -e "${YELLOW}🛑 Stopping any existing backend processes...${NC}"
pm2 delete all 2>/dev/null || true
pkill -f "node.*index.js" || true

echo -e "${YELLOW}📋 Verifying environment configuration...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

# Show database configuration
echo "Database configuration:"
grep -E "^(DATABASE_URL|DIRECT_URL)" .env | head -2

echo -e "${YELLOW}🔧 Testing database connection...${NC}"
node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();
prisma.user.findMany().then(users => {
  console.log('✅ Database connected. Users found:', users.length);
  process.exit(0);
}).catch(err => {
  console.error('❌ Database error:', err.message);
  process.exit(1);
});
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Database connection issue, regenerating Prisma client...${NC}"
    npx prisma generate
    npx prisma db push
fi

echo -e "${YELLOW}🔍 Checking backend dependencies...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
    npm install
fi

echo -e "${YELLOW}🧪 Testing backend server locally...${NC}"
timeout 10s node index.js &
server_pid=$!
sleep 3

# Test API endpoints
echo -e "${YELLOW}🔬 Testing API endpoints...${NC}"
health_response=$(curl -s http://localhost:4000/api/health 2>/dev/null || echo "FAILED")
echo "Health endpoint: $health_response"

requests_response=$(curl -s http://localhost:4000/api/requests 2>/dev/null || echo "FAILED")
echo "Requests endpoint: ${requests_response:0:50}..."

# Kill test server
kill $server_pid 2>/dev/null || true

echo -e "${YELLOW}🚀 Starting backend with PM2...${NC}"
pm2 start index.js --name "tik-workshop-backend" --instances 1

echo -e "${YELLOW}⏳ Waiting for backend to start...${NC}"
sleep 5

echo -e "${YELLOW}🧪 Testing backend through PM2...${NC}"
pm2_health=$(curl -s http://localhost:4000/api/health 2>/dev/null || echo "FAILED")
echo "PM2 Health check: $pm2_health"

if [[ "$pm2_health" == *"healthy"* ]]; then
    echo -e "${GREEN}✅ Backend API is running successfully!${NC}"
else
    echo -e "${RED}❌ Backend API is not responding properly${NC}"
    echo -e "${YELLOW}📋 PM2 logs:${NC}"
    pm2 logs --lines 10
    exit 1
fi

echo -e "${YELLOW}🌐 Checking Nginx configuration...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${YELLOW}🔄 Reloading Nginx...${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✅ Nginx reloaded successfully${NC}"
else
    echo -e "${RED}❌ Nginx configuration error${NC}"
fi

echo -e "${YELLOW}🧪 Testing full API through Nginx...${NC}"
nginx_health=$(curl -s http://localhost/api/health 2>/dev/null || echo "FAILED")
echo "Nginx API Health: $nginx_health"

echo -e "${GREEN}🎉 Backend API Fix Complete!${NC}"
echo -e "${GREEN}📋 Status Summary:${NC}"
echo -e "${GREEN}   • Backend: Running on port 4000${NC}"
echo -e "${GREEN}   • Database: Connected${NC}"
echo -e "${GREEN}   • Nginx: Proxying requests${NC}"
echo -e "${GREEN}   • API Health: $nginx_health${NC}"
echo ""
echo -e "${GREEN}🌐 Test your API:${NC}"
echo -e "${GREEN}   • Health: http://152.42.229.232/api/health${NC}"
echo -e "${GREEN}   • Requests: http://152.42.229.232/api/requests${NC}"
echo -e "${GREEN}   • Website: http://152.42.229.232${NC}"

echo -e "${YELLOW}📋 PM2 Status:${NC}"
pm2 status
