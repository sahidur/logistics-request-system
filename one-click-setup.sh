#!/bin/bash

# 🚀 TikTok Workshop - ONE CLICK SETUP
# Run this on your server: 152.42.229.232
# Usage: chmod +x one-click-setup.sh && sudo ./one-click-setup.sh

set -e

echo "🎯 TikTok Learning Sharing Workshop - ONE CLICK SETUP"
echo "====================================================="
echo "🖥️  Server: 152.42.229.232"
echo "🌐 Domain: tiktok.somadhanhobe.com"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1 failed${NC}"
        exit 1
    fi
}

echo -e "${BLUE}📋 Step 1: System Preparation${NC}"
echo "================================================"

# Update system
echo -e "${YELLOW}🔄 Updating system packages...${NC}"
apt update && apt upgrade -y
check_success "System update"

# Install essential packages
echo -e "${YELLOW}📦 Installing essential packages...${NC}"
apt install -y curl wget git unzip software-properties-common ufw
check_success "Essential packages installation"

echo -e "${BLUE}📋 Step 2: Install Core Software${NC}"
echo "================================================"

# Install Node.js 18
echo -e "${YELLOW}📦 Installing Node.js 18...${NC}"
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
check_success "Node.js installation"

# Install PM2
echo -e "${YELLOW}📦 Installing PM2...${NC}"
npm install -g pm2
check_success "PM2 installation"

# Install Nginx
echo -e "${YELLOW}📦 Installing Nginx...${NC}"
apt install -y nginx
check_success "Nginx installation"

# Install Certbot for SSL
echo -e "${YELLOW}🔒 Installing Certbot for SSL...${NC}"
apt install -y certbot python3-certbot-nginx
check_success "Certbot installation"

echo -e "${BLUE}📋 Step 3: Setup Application${NC}"
echo "================================================"

# Create app directory
APP_DIR="/var/www/tik-workshop"
echo -e "${YELLOW}📁 Creating application directory: $APP_DIR${NC}"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone repository
echo -e "${YELLOW}📥 Cloning repository...${NC}"
if [ -d ".git" ]; then
    git pull origin main
else
    git clone https://github.com/sahidur/logistics-request-system.git .
fi
check_success "Repository clone/update"

echo -e "${BLUE}📋 Step 4: Configure Backend${NC}"
echo "================================================"

# Setup backend
echo -e "${YELLOW}⚙️ Setting up backend...${NC}"
cd $APP_DIR/backend

# Copy production environment file from repository root
echo -e "${YELLOW}📋 Configuring production environment...${NC}"
if [ -f "../.env.production" ]; then
    cp ../.env.production .env
    echo -e "${GREEN}✅ Production environment copied from repository${NC}"
    
    # Show database configuration status
    DB_URL=$(grep "DATABASE_URL=" .env | cut -d'=' -f2- | tr -d '"')
    if [ -n "$DB_URL" ]; then
        echo -e "${GREEN}✅ Database URL configured${NC}"
    else
        echo -e "${RED}❌ Database URL not found in .env.production${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  .env.production not found, creating basic configuration...${NC}"
    echo -e "${YELLOW}📝 Please enter your database URL:${NC}"
    echo "Example: postgresql://username:password@host:port/database?sslmode=require"
    read -r database_url
    
    cat > .env << EOF
NODE_ENV=production
PORT=4000
JWT_SECRET=TikTok_Workshop_2025_Production_JWT_Secret_152_42_229_232_SecureKey_xyz789
DATABASE_URL=$database_url
EOF
fi

# Install backend dependencies
echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
npm install --production
check_success "Backend dependencies installation"

# Generate Prisma client
echo -e "${YELLOW}🗄️ Generating Prisma client...${NC}"
npx prisma generate
check_success "Prisma client generation"

# Run database migrations to create tables
echo -e "${YELLOW}🏗️ Running database migrations...${NC}"
npx prisma migrate deploy || npx prisma db push
check_success "Database migrations"

# Test database connection
echo -e "${YELLOW}🧪 Testing database connection...${NC}"

# Load environment variables for subsequent commands
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();
prisma.user.findMany().then(users => {
  console.log('✅ Database connected successfully. Users found:', users.length);
  process.exit(0);
}).catch(err => {
  console.error('❌ Database connection error:', err.message);
  console.log('Please check your DATABASE_URL in .env file');
  process.exit(1);
});
"
check_success "Database connection test"

# Seed database with admin user if needed
echo -e "${YELLOW}👤 Setting up admin user...${NC}"
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
" || echo -e "${YELLOW}⚠️  Admin setup failed, but continuing...${NC}"

echo -e "${BLUE}📋 Step 5: Configure Frontend${NC}"
echo "================================================"

# Setup frontend
echo -e "${YELLOW}⚙️ Setting up frontend...${NC}"
cd $APP_DIR/frontend

# Create production environment file
cat > .env.production << EOF
VITE_API_URL=https://tiktok.somadhanhobe.com/api
VITE_API_URL_HTTP=http://152.42.229.232:4000/api
EOF

# Install frontend dependencies
echo -e "${YELLOW}📦 Installing frontend dependencies...${NC}"
npm install
check_success "Frontend dependencies installation"

# Build frontend
echo -e "${YELLOW}🔨 Building frontend...${NC}"
npm run build
check_success "Frontend build"

echo -e "${BLUE}📋 Step 6: Configure Nginx${NC}"
echo "================================================"

# Create Nginx configuration
echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/default << 'EOF'
# TikTok Workshop - Basic HTTP Configuration
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name tiktok.somadhanhobe.com 152.42.229.232;
    root /var/www/tik-workshop/frontend/dist;
    index index.html;
    
    # Frontend routes
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:4000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Handle file uploads
    client_max_body_size 50M;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

# Test and reload Nginx
nginx -t
check_success "Nginx configuration test"

systemctl reload nginx
check_success "Nginx reload"

echo -e "${BLUE}📋 Step 7: Configure Firewall${NC}"
echo "================================================"

# Configure UFW firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80
ufw allow 443
ufw allow 4000
ufw --force enable
check_success "Firewall configuration"

echo -e "${BLUE}📋 Step 8: Start Services${NC}"
echo "================================================"

# Start backend with PM2
echo -e "${YELLOW}🚀 Starting backend service...${NC}"
cd $APP_DIR/backend
pm2 delete all 2>/dev/null || true
pm2 start index.js --name "tik-workshop-backend" --instances 2
pm2 save
pm2 startup systemd -u root --hp /root
check_success "Backend service start"

echo -e "${BLUE}📋 Step 9: Setup SSL (Optional)${NC}"
echo "================================================"

echo -e "${YELLOW}🔒 Do you want to setup SSL certificate? (y/N):${NC}"
read -r setup_ssl
if [[ $setup_ssl =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🔒 Setting up SSL certificate...${NC}"
    certbot --nginx -d tiktok.somadhanhobe.com --non-interactive --agree-tos --email admin@somadhanhobe.com
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSL certificate installed successfully${NC}"
    else
        echo -e "${YELLOW}⚠️ SSL setup failed, but site will work with HTTP${NC}"
    fi
fi

echo -e "${BLUE}📋 Step 10: Final Verification${NC}"
echo "================================================"

# Test services
echo -e "${YELLOW}🧪 Testing services...${NC}"
sleep 5

# Test backend
curl -s http://localhost:4000/api/health > /dev/null
check_success "Backend health check"

# Test frontend
curl -s http://localhost > /dev/null
check_success "Frontend health check"

echo ""
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE! 🎉${NC}"
echo "================================="
echo ""
echo -e "${BLUE}📋 Your TikTok Workshop is now live at:${NC}"
echo -e "${GREEN}🌐 Website: http://tiktok.somadhanhobe.com${NC}"
echo -e "${GREEN}🌐 IP Access: http://152.42.229.232${NC}"
echo -e "${GREEN}👨‍💼 Admin Panel: http://tiktok.somadhanhobe.com/admin${NC}"
echo ""
echo -e "${BLUE}📋 Service Management:${NC}"
echo "• Backend Status: pm2 status"
echo "• Backend Logs: pm2 logs tik-workshop-backend"
echo "• Restart Backend: pm2 restart tik-workshop-backend"
echo "• Nginx Status: systemctl status nginx"
echo "• Nginx Logs: tail -f /var/log/nginx/error.log"
echo ""
echo -e "${BLUE}📋 Default Admin Login:${NC}"
echo "• Email: admin@logistics.com"
echo "• Password: admin123"
echo ""
echo -e "${YELLOW}⚠️ Remember to:${NC}"
echo "1. Change default admin password"
echo "2. Configure your domain DNS to point to 152.42.229.232"
echo "3. Monitor logs regularly"
echo ""
echo -e "${GREEN}✨ Happy workshopping! ✨${NC}"
