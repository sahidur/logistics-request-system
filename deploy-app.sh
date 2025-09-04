#!/bin/bash

# TikTok Workshop App Deployment Script
set -e

echo "🚀 Deploying TikTok Learning Sharing Workshop"
echo "============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_DIR="/var/www/tik-workshop"
APP_USER="tikworkshop"
DOMAIN="your-domain.com"

# Create application user if doesn't exist
if ! id "$APP_USER" &>/dev/null; then
    echo -e "${YELLOW}👤 Creating application user...${NC}"
    useradd -m -s /bin/bash $APP_USER
fi

# Create application directory
echo -e "${YELLOW}📁 Setting up application directory...${NC}"
mkdir -p $APP_DIR
chown $APP_USER:$APP_USER $APP_DIR

# Copy application files (assuming they're in current directory)
echo -e "${YELLOW}📋 Copying application files...${NC}"
cp -r . $APP_DIR/
chown -R $APP_USER:$APP_USER $APP_DIR

# Switch to app directory
cd $APP_DIR

# Check for environment file
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚙️  Creating environment file from example...${NC}"
    cp .env.example .env
    echo -e "${RED}⚠️  Please update the .env file with your production values!${NC}"
fi

# Install backend dependencies
echo -e "${YELLOW}📦 Installing backend dependencies...${NC}"
cd backend
sudo -u $APP_USER npm ci --only=production

# Generate Prisma client
echo -e "${YELLOW}🔧 Generating Prisma client...${NC}"
sudo -u $APP_USER npx prisma generate

# Run database migrations
echo -e "${YELLOW}🗄️  Running database migrations...${NC}"
sudo -u $APP_USER npx prisma db push

# Seed database with admin user
echo -e "${YELLOW}🌱 Seeding database...${NC}"
sudo -u $APP_USER npm run seed

# Install frontend dependencies and build
echo -e "${YELLOW}🎨 Building frontend...${NC}"
cd ../frontend
sudo -u $APP_USER npm ci
sudo -u $APP_USER npm run build

# Set up PM2 for backend
echo -e "${YELLOW}⚡ Setting up PM2 process management...${NC}"
cd ../backend

# Create PM2 ecosystem file
sudo -u $APP_USER cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'tik-workshop-backend',
    script: 'index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 4000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
EOF

# Create logs directory
sudo -u $APP_USER mkdir -p logs

# Start the application with PM2
sudo -u $APP_USER pm2 start ecosystem.config.js
sudo -u $APP_USER pm2 save
sudo -u $APP_USER pm2 startup

# Configure Nginx
echo -e "${YELLOW}🌐 Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/tik-workshop << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    root $APP_DIR/frontend/dist;
    index index.html index.htm;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Frontend (React SPA)
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API proxy
    location /api/ {
        proxy_pass http://localhost:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:4000/health;
        access_log off;
    }

    # Uploads
    location /uploads/ {
        proxy_pass http://localhost:4000/uploads/;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/tik-workshop /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and reload Nginx
nginx -t && systemctl reload nginx

# Set up SSL with Let's Encrypt (optional)
echo -e "${YELLOW}🔒 Do you want to set up SSL with Let's Encrypt? (y/N):${NC}"
read -r setup_ssl
if [[ $setup_ssl =~ ^[Yy]$ ]]; then
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d $DOMAIN -d www.$DOMAIN
fi

# Set up firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo -e "${GREEN}🎉 Deployment complete!${NC}"
echo ""
echo -e "${BLUE}📋 Deployment Summary:${NC}"
echo -e "App Directory: ${YELLOW}$APP_DIR${NC}"
echo -e "App User: ${YELLOW}$APP_USER${NC}"
echo -e "Frontend: ${YELLOW}http://$DOMAIN${NC}"
echo -e "Backend API: ${YELLOW}http://$DOMAIN/api${NC}"
echo -e "Admin Login: ${YELLOW}http://$DOMAIN/admin${NC}"
echo ""
echo -e "${BLUE}🔧 Management Commands:${NC}"
echo -e "View logs: ${YELLOW}sudo -u $APP_USER pm2 logs${NC}"
echo -e "Restart app: ${YELLOW}sudo -u $APP_USER pm2 restart all${NC}"
echo -e "Stop app: ${YELLOW}sudo -u $APP_USER pm2 stop all${NC}"
echo ""
echo -e "${RED}⚠️  Important:${NC}"
echo "1. Update the .env file with your production database and JWT secret"
echo "2. Change default admin password after first login"
echo "3. Configure your domain name in the deployment script"
