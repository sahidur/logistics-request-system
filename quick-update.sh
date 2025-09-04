#!/bin/bash

# 🔄 Quick Update Script for Existing TikTok Workshop Deployment
# Run this on your server to update the existing installation

set -e

echo "🔄 TikTok Workshop - Quick Update"
echo "================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
APP_DIR="/var/www/tik-workshop"

# Check if we're in the right directory
if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}❌ Project directory not found: $APP_DIR${NC}"
    echo "Please run the one-click setup first or check the path"
    exit 1
fi

cd $APP_DIR

echo -e "${YELLOW}📥 Step 1: Pull latest code from GitHub...${NC}"
git pull origin main
echo -e "${GREEN}✅ Code updated${NC}"

echo ""
echo -e "${YELLOW}🔧 Step 2: Update backend dependencies...${NC}"
cd $APP_DIR/backend

# Remove node_modules and reinstall to fix bcrypt issues
echo -e "${YELLOW}   🗑️  Cleaning old dependencies...${NC}"
rm -rf node_modules package-lock.json

# Install build essentials if not present (needed for bcrypt)
if ! dpkg -l | grep -q build-essential; then
    echo -e "${YELLOW}   🔨 Installing build tools...${NC}"
    apt update
    apt install -y build-essential python3
fi

# Reinstall dependencies
echo -e "${YELLOW}   📦 Installing dependencies (including bcrypt)...${NC}"
npm install

# Generate Prisma client
echo -e "${YELLOW}   🗄️  Regenerating Prisma client...${NC}"
npx prisma generate

echo -e "${GREEN}✅ Backend dependencies updated${NC}"

echo ""
echo -e "${YELLOW}🎨 Step 3: Update frontend...${NC}"
cd $APP_DIR/frontend

# Update frontend dependencies
echo -e "${YELLOW}   📦 Installing frontend dependencies...${NC}"
npm install

# Rebuild frontend
echo -e "${YELLOW}   🔨 Building frontend...${NC}"
npm run build

echo -e "${GREEN}✅ Frontend updated and built${NC}"

echo ""
echo -e "${YELLOW}🧪 Step 4: Test database connection...${NC}"
cd $APP_DIR/backend

# Copy production environment if it exists
if [ -f "../.env.production" ] && [ ! -f ".env" ]; then
    echo -e "${YELLOW}   📋 Copying production environment...${NC}"
    cp ../.env.production .env
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs 2>/dev/null)
fi

# Test database connection
node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();
prisma.user.findMany().then(users => {
  console.log('✅ Database connected successfully. Users found:', users.length);
  process.exit(0);
}).catch(err => {
  console.error('❌ Database connection error:', err.message);
  process.exit(1);
});
"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}👤 Step 5: Ensure admin user exists...${NC}"

node -e "
const { PrismaClient } = require('./generated/prisma');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function setupAdmin() {
  try {
    const existingAdmin = await prisma.user.findUnique({
      where: { email: 'admin@logistics.com' }
    });
    
    if (!existingAdmin) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      await prisma.user.create({
        data: {
          name: 'Admin',
          email: 'admin@logistics.com',
          password: hashedPassword,
          teamName: 'Administration'
        }
      });
      console.log('✅ Admin user created successfully');
    } else {
      console.log('✅ Admin user already exists');
    }
    process.exit(0);
  } catch (error) {
    console.error('❌ Error setting up admin:', error.message);
    process.exit(1);
  }
}

setupAdmin();
"

echo ""
echo -e "${YELLOW}🚀 Step 6: Restart services...${NC}"

# Stop existing PM2 processes
echo -e "${YELLOW}   🛑 Stopping existing backend...${NC}"
pm2 delete all 2>/dev/null || true

# Start backend with PM2
echo -e "${YELLOW}   🚀 Starting updated backend...${NC}"
pm2 start index.js --name "tik-workshop-backend" --instances 2
pm2 save

# Reload nginx
echo -e "${YELLOW}   🔄 Reloading Nginx...${NC}"
systemctl reload nginx

echo -e "${GREEN}✅ Services restarted${NC}"

echo ""
echo -e "${YELLOW}🧪 Step 7: Final verification...${NC}"

# Wait for services to start
sleep 5

# Test API
if curl -s http://localhost:4000/api/health > /dev/null; then
    echo -e "${GREEN}✅ API server responding${NC}"
else
    echo -e "${RED}❌ API server not responding${NC}"
fi

# Test frontend
if curl -s http://localhost > /dev/null; then
    echo -e "${GREEN}✅ Frontend accessible${NC}"
else
    echo -e "${RED}❌ Frontend not accessible${NC}"
fi

echo ""
echo -e "${GREEN}🎉 UPDATE COMPLETE! 🎉${NC}"
echo "=========================="
echo ""
echo -e "${GREEN}🌐 Your TikTok Workshop is updated and running:${NC}"
echo -e "${GREEN}   • Website: http://146.190.106.123${NC}"
echo -e "${GREEN}   • Domain: http://tiktok.somadhanhobe.com (if DNS is configured)${NC}"
echo -e "${GREEN}   • Admin: http://146.190.106.123/admin${NC}"
echo ""
echo -e "${YELLOW}📋 Admin Login:${NC}"
echo "   Email: admin@logistics.com"
echo "   Password: admin123"
echo ""
echo -e "${YELLOW}🔧 Service Management:${NC}"
echo "   • Backend status: pm2 status"
echo "   • Backend logs: pm2 logs tik-workshop-backend"
echo "   • Restart backend: pm2 restart tik-workshop-backend"
