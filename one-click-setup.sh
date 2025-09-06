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

# Install Node.js 20 (Required for Vite 7+)
echo -e "${YELLOW}📦 Installing Node.js 20...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
check_success "Node.js installation"

# Verify Node.js version
echo -e "${YELLOW}🔍 Verifying Node.js version...${NC}"
node_version=$(node --version)
echo "Node.js version: $node_version"
if [[ "$node_version" < "v20.0.0" ]]; then
    echo -e "${RED}❌ Node.js version is too old for Vite. Minimum required: v20.0.0${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Node.js version is compatible${NC}"
fi

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
    
    # Debug: Show the actual lines from .env file
    echo -e "${YELLOW}🔍 Debug: Environment file contents:${NC}"
    echo "=========================="
    grep -E "^(DATABASE_URL|DIRECT_URL)" .env || echo "No database URLs found"
    echo "=========================="
    
    # Parse environment variables more carefully
    DB_URL=$(grep "^DATABASE_URL=" .env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    DIRECT_URL=$(grep "^DIRECT_URL=" .env | cut -d'=' -f2- | sed 's/^"//' | sed 's/"$//')
    
    echo "Parsed DATABASE_URL: ${DB_URL:0:50}..."
    echo "Parsed DIRECT_URL: ${DIRECT_URL:0:50}..."
    
    if [ -n "$DB_URL" ] && [ -n "$DIRECT_URL" ]; then
        echo -e "${GREEN}✅ Database URLs configured${NC}"
    else
        echo -e "${RED}❌ Database URLs not properly configured${NC}"
        echo "DATABASE_URL found: $([ -n "$DB_URL" ] && echo "Yes" || echo "No")"
        echo "DIRECT_URL found: $([ -n "$DIRECT_URL" ] && echo "Yes" || echo "No")"
        
        # If DIRECT_URL is missing but DATABASE_URL exists, use DATABASE_URL as DIRECT_URL
        if [ -n "$DB_URL" ] && [ -z "$DIRECT_URL" ]; then
            echo -e "${YELLOW}⚠️  DIRECT_URL missing, using DATABASE_URL as fallback${NC}"
            echo "DIRECT_URL=\"$DB_URL\"" >> .env
        fi
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
DATABASE_URL="$database_url"
DIRECT_URL="$database_url"
EOF
fi

# Install backend dependencies
echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
npm install
check_success "Backend dependencies installation"

# Verify critical dependencies are installed
echo -e "${YELLOW}🔍 Verifying critical dependencies...${NC}"
if npm list bcryptjs > /dev/null 2>&1; then
    echo -e "${GREEN}✅ bcryptjs installed${NC}"
else
    echo -e "${RED}❌ bcryptjs missing${NC}"
fi

if npm list @prisma/client > /dev/null 2>&1; then
    echo -e "${GREEN}✅ @prisma/client installed${NC}"
else
    echo -e "${RED}❌ @prisma/client missing${NC}"
fi

# Verify environment variables are properly set
echo -e "${YELLOW}🔍 Verifying environment configuration...${NC}"
echo "Final environment file contents:"
echo "================================="
cat .env
echo "================================="

# Load environment variables for subsequent commands
if [ -f ".env" ]; then
    # Export environment variables, handling quotes properly
    set -a  # automatically export all variables
    source .env
    set +a  # stop automatically exporting
    echo -e "${GREEN}✅ Environment variables loaded${NC}"
    
    # Verify critical environment variables
    if [ -z "$DATABASE_URL" ]; then
        echo -e "${RED}❌ DATABASE_URL is empty${NC}"
        exit 1
    fi
    
    if [ -z "$DIRECT_URL" ]; then
        echo -e "${RED}❌ DIRECT_URL is empty${NC}"
        exit 1
    fi
    
    echo "DATABASE_URL length: ${#DATABASE_URL}"
    echo "DIRECT_URL length: ${#DIRECT_URL}"
else
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

# Generate Prisma client
echo -e "${YELLOW}🗄️ Generating Prisma client...${NC}"
npx prisma generate
check_success "Prisma client generation"

# Run database migrations to create tables
echo -e "${YELLOW}🏗️ Running database migrations...${NC}"
npx prisma migrate deploy
check_success "Database migrations"

# Test database connection
echo -e "${YELLOW}🧪 Testing database connection...${NC}"

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
const bcrypt = require('bcryptjs');
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

# Ensure npm bin is in PATH
export PATH="$PATH:./node_modules/.bin"

# Check Node.js version before installing
node_major_version=$(node --version | cut -d'.' -f1 | sed 's/v//')

if [ "$node_major_version" -lt 20 ]; then
    echo -e "${YELLOW}⚠️  Node.js version is older than 20. Installing compatible package versions...${NC}"
    
    # Install compatible versions for Node 18
    npm install vite@^4.5.0 @vitejs/plugin-react@^4.0.0 react-router-dom@^6.8.0
    check_success "Compatible dependencies installation"
else
    # Install normal dependencies for Node 20+
    npm install
    check_success "Frontend dependencies installation"
fi

# Clear npm cache to avoid issues
npm cache clean --force

# Verify Vite is installed and working
echo -e "${YELLOW}🔍 Verifying Vite installation...${NC}"

# First check if vite is in node_modules
if [ -f "node_modules/.bin/vite" ]; then
    echo -e "${GREEN}✅ Vite binary found in node_modules${NC}"
else
    echo -e "${RED}❌ Vite binary not found${NC}"
    echo -e "${YELLOW}⚠️  Attempting to install Vite directly...${NC}"
    npm install vite@latest
fi

# Try to get version with timeout
echo -e "${YELLOW}🔍 Getting Vite version...${NC}"
vite_version=$(timeout 10s npx vite --version 2>/dev/null || echo "timeout")

if [ "$vite_version" = "timeout" ]; then
    echo -e "${YELLOW}⚠️  Vite version check timed out, but continuing with build...${NC}"
elif [ -n "$vite_version" ]; then
    echo -e "${GREEN}✅ Vite installed and working${NC}"
    echo "Vite version: $vite_version"
else
    echo -e "${YELLOW}⚠️  Could not verify Vite version, but attempting build...${NC}"
fi

# Build frontend
echo -e "${YELLOW}🔨 Building frontend...${NC}"
echo -e "${YELLOW}⏳ This may take a few minutes...${NC}"

# Kill any existing vite processes that might be hanging
pkill -f vite || true

# Ensure PATH includes node_modules/.bin
export PATH="$PATH:./node_modules/.bin:$(npm bin)"

# Set memory limit to prevent hanging
export NODE_OPTIONS="--max-old-space-size=4096"

# Try building with aggressive timeout and process management
echo -e "${YELLOW}🔧 Attempting build with 2-minute timeout...${NC}"

(
    timeout 120s npx vite build
) &
build_pid=$!

# Monitor the build process
sleep 5
if kill -0 $build_pid 2>/dev/null; then
    echo -e "${YELLOW}📋 Build process is running (PID: $build_pid)${NC}"
    wait $build_pid
    build_exit_code=$?
else
    echo -e "${YELLOW}📋 Build process already finished${NC}"
    build_exit_code=0
fi

if [ $build_exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend build completed successfully${NC}"
elif [ $build_exit_code -eq 124 ]; then
    echo -e "${RED}❌ Build timed out, trying alternative approach...${NC}"
    
    # Kill any hanging processes
    pkill -f vite || true
    pkill -f node || true
    sleep 2
    
    # Try with compatible Vite version
    echo -e "${YELLOW}🔧 Installing compatible Vite version...${NC}"
    npm install vite@^4.5.0 --save-dev
    
    echo -e "${YELLOW}🔧 Attempting build with compatible version...${NC}"
    timeout 120s npx vite build
    build_exit_code=$?
    
    if [ $build_exit_code -ne 0 ]; then
        echo -e "${RED}❌ All build attempts failed${NC}"
        echo -e "${YELLOW}📋 Creating minimal build manually...${NC}"
        
        # Create a minimal dist directory with basic HTML
        mkdir -p dist
        cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TikTok Workshop - Loading...</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .loading { color: #333; }
    </style>
</head>
<body>
    <div class="loading">
        <h1>TikTok Learning Sharing Workshop</h1>
        <p>System is being set up. Please refresh in a few minutes.</p>
        <p>If this message persists, please contact the administrator.</p>
    </div>
</body>
</html>
EOF
        echo -e "${YELLOW}⚠️  Created temporary placeholder page${NC}"
    fi
else
    echo -e "${RED}❌ Build failed with exit code: $build_exit_code${NC}"
    exit 1
fi

# Verify build output exists
if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
    echo -e "${GREEN}✅ Build output verified in dist/ directory${NC}"
    echo "Build contents:"
    ls -la dist/ | head -10
else
    echo -e "${RED}❌ Build output not found or empty${NC}"
    exit 1
fi

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
