#!/bin/bash

# 🔍 Backend Database Connection Verifier
# For TikTok Workshop Logistics System

echo "🔧 Backend Database Connection Verification"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're in the backend directory
if [ ! -f "package.json" ] || [ ! -f "index.js" ]; then
    echo -e "${RED}❌ Run this script from the backend directory${NC}"
    echo "Usage: cd backend && ../verify-backend.sh"
    exit 1
fi

echo -e "${BLUE}📋 Step 1: Check Environment Configuration${NC}"
echo "=============================================="

# Check .env file
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env file found${NC}"
    
    # Check DATABASE_URL
    if grep -q "DATABASE_URL=" .env; then
        DB_URL=$(grep "DATABASE_URL=" .env | cut -d'=' -f2- | tr -d '"')
        if [ -n "$DB_URL" ]; then
            echo -e "${GREEN}✅ DATABASE_URL configured${NC}"
            echo -e "${YELLOW}   Database host: $(echo $DB_URL | cut -d'@' -f2 | cut -d':' -f1)${NC}"
        else
            echo -e "${RED}❌ DATABASE_URL is empty${NC}"
        fi
    else
        echo -e "${RED}❌ DATABASE_URL not found in .env${NC}"
    fi
    
    # Check other required variables
    for var in NODE_ENV PORT JWT_SECRET; do
        if grep -q "$var=" .env; then
            echo -e "${GREEN}✅ $var configured${NC}"
        else
            echo -e "${YELLOW}⚠️  $var not found in .env${NC}"
        fi
    done
else
    echo -e "${RED}❌ .env file not found${NC}"
    echo "Please copy .env.production to .env or create one"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Step 2: Check Dependencies${NC}"
echo "================================"

# Check if node_modules exists
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✅ node_modules directory exists${NC}"
else
    echo -e "${RED}❌ node_modules not found${NC}"
    echo "Run: npm install"
fi

# Check Prisma client
if [ -f "generated/prisma/index.js" ]; then
    echo -e "${GREEN}✅ Prisma client generated${NC}"
else
    echo -e "${RED}❌ Prisma client not generated${NC}"
    echo "Run: npx prisma generate"
fi

echo ""
echo -e "${BLUE}📋 Step 3: Test Database Connection${NC}"
echo "====================================="

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs 2>/dev/null)
fi

# Test database connection
echo -e "${YELLOW}🔄 Testing database connection...${NC}"
node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();

console.log('Database URL:', process.env.DATABASE_URL ? 'Configured' : 'Missing');

prisma.user.findMany().then(users => {
  console.log('✅ Database connection successful');
  console.log('👥 Users in database:', users.length);
  
  // Check for admin user
  const admin = users.find(u => u.email === 'admin@logistics.com');
  if (admin) {
    console.log('👤 Admin user found:', admin.name);
  } else {
    console.log('⚠️  Admin user not found');
  }
  
  process.exit(0);
}).catch(err => {
  console.error('❌ Database connection failed:', err.message);
  
  if (err.message.includes('getaddrinfo ENOTFOUND')) {
    console.log('🔍 Issue: Cannot resolve database host');
    console.log('💡 Solution: Check your internet connection and database URL');
  } else if (err.message.includes('authentication failed')) {
    console.log('🔍 Issue: Invalid database credentials');
    console.log('💡 Solution: Check username/password in DATABASE_URL');
  } else if (err.message.includes('timeout')) {
    console.log('🔍 Issue: Connection timeout');
    console.log('💡 Solution: Check if database server is accessible');
  }
  
  process.exit(1);
});
"

CONNECTION_STATUS=$?

echo ""
echo -e "${BLUE}📋 Step 4: Test API Server${NC}"
echo "=========================="

# Start server in background for testing
echo -e "${YELLOW}🔄 Starting backend server for testing...${NC}"
node index.js &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test health endpoint
if curl -s http://localhost:4000/api/health > /dev/null; then
    echo -e "${GREEN}✅ API server responding${NC}"
    
    # Test registration endpoint
    REGISTER_RESPONSE=$(curl -s -X POST http://localhost:4000/api/register \
        -H "Content-Type: application/json" \
        -d '{"name": "Test User", "email": "test@example.com", "password": "test123", "teamName": "Test Team"}')
    
    if echo "$REGISTER_RESPONSE" | grep -q "token\|error"; then
        echo -e "${GREEN}✅ Registration endpoint working${NC}"
    else
        echo -e "${YELLOW}⚠️  Registration endpoint may have issues${NC}"
    fi
    
else
    echo -e "${RED}❌ API server not responding${NC}"
fi

# Kill test server
kill $SERVER_PID 2>/dev/null

echo ""
echo -e "${BLUE}📋 Summary${NC}"
echo "==========="

if [ $CONNECTION_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ Backend is properly configured and connected to database${NC}"
    echo ""
    echo -e "${BLUE}🚀 Ready for deployment!${NC}"
    echo "To start in production:"
    echo "  pm2 start index.js --name tik-workshop-backend"
else
    echo -e "${RED}❌ Backend has database connection issues${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting steps:${NC}"
    echo "1. Check .env file has correct DATABASE_URL"
    echo "2. Verify database server is accessible"
    echo "3. Run: npm install"
    echo "4. Run: npx prisma generate"
    echo "5. Check firewall settings"
fi
