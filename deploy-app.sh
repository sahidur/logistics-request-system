#!/bin/bash

# TikTok Workshop App Deployment Script - COMPLETE DEPLOYMENT
set echo "🌐 Setting up Nginx configuration..."
# Remove any conflicting configs that might redirect to wdp.joycalls.com
find /etc/nginx -name "*.conf" -exec grep -l "wdp.joycalls.com" {} + 2>/dev/null | while read file; do
    echo "  🗑️  Removing conflicting config: $file"
    mv "$file" "$file.disabled.$(date +%Y%m%d_%H%M%S)"
done

# Deploy our nginx configuration
cp frontend/nginx.conf /etc/nginx/sites-available/default
nginx -t
if [ $? -eq 0 ]; then
    systemctl reload nginx
    echo "  ✅ Nginx configuration updated"
else
    echo "  ❌ Nginx configuration error!"
    exit 1
ficho "🚀 Deploying TikTok Learning Sharing Workshop - COMPLETE SYSTEM"
echo "================================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_DIR="/var/www/tik-workshop"
APP_USER="tikworkshop"
DOMAIN="139.59.122.235"
NGINX_ROOT="/var/www/html"

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

# Copy production environment files
echo "📝 Setting up production environment..."
if [ ! -f .env.production ]; then
    echo "❌ ERROR: .env.production file not found!"
    echo "Please create .env.production with your database credentials"
    exit 1
fi
cp .env.production backend/.env
cp frontend/.env.production frontend/.env

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
echo -e "${YELLOW}🎨 Building frontend with production config...${NC}"
cd ../frontend

# Install dependencies
sudo -u $APP_USER npm ci

# Build with production environment
echo -e "${BLUE}📦 Building React app for production...${NC}"
sudo -u $APP_USER npm run build

# Deploy frontend to Nginx
echo -e "${YELLOW}🌐 Deploying frontend to Nginx...${NC}"
rm -rf $NGINX_ROOT/*
cp -r dist/* $NGINX_ROOT/
chown -R www-data:www-data $NGINX_ROOT
chmod -R 755 $NGINX_ROOT

# Verify frontend deployment
if [ -f "$NGINX_ROOT/index.html" ]; then
    echo -e "${GREEN}✅ Frontend deployed successfully${NC}"
else
    echo -e "${RED}❌ Frontend deployment failed${NC}"
    exit 1
fi

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

# Configure Nginx for complete SPA + Admin support
echo -e "${YELLOW}🌐 Configuring Nginx with admin route support...${NC}"
cat > /etc/nginx/sites-available/tik-workshop << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root $NGINX_ROOT;
    index index.html index.htm;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;

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

    # File uploads
    location /uploads/ {
        proxy_pass http://localhost:4000/uploads/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # React SPA - Handle all routes including /admin
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF

# Enable the site and remove default
echo -e "${YELLOW}🔧 Activating Nginx configuration...${NC}"
ln -sf /etc/nginx/sites-available/tik-workshop /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo -e "${YELLOW}🧪 Testing Nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
    systemctl reload nginx
    systemctl enable nginx
    systemctl start nginx
else
    echo -e "${RED}❌ Nginx configuration error${NC}"
    exit 1
fi

# Verify services are running
echo -e "${YELLOW}🔍 Verifying services...${NC}"
sleep 3

# Check PM2 status
if sudo -u $APP_USER pm2 list | grep -q "online"; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend is not running${NC}"
fi

# Check Nginx status
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx is running${NC}"
else
    echo -e "${RED}❌ Nginx is not running${NC}"
fi

# Test API endpoint
if curl -f http://localhost:4000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API health check passed${NC}"
else
    echo -e "${YELLOW}⚠️  API health check failed - may be starting up${NC}"
fi

# Set up SSL with Let's Encrypt (optional)
echo -e "${YELLOW}🔒 Do you want to set up SSL with Let's Encrypt? (y/N):${NC}"
read -r setup_ssl
if [[ $setup_ssl =~ ^[Yy]$ ]]; then
    apt install -y certbot python3-certbot-nginx
    certbot --nginx -d $DOMAIN -d www.$DOMAIN
fi
fi

# Set up firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo -e "${GREEN}🎉 DEPLOYMENT COMPLETE!${NC}"
echo ""
echo -e "${BLUE}📋 DEPLOYMENT SUMMARY:${NC}"
echo -e "==============================================="
echo -e "🌐 Website: ${GREEN}http://$DOMAIN${NC}"
echo -e "👤 Admin Panel: ${GREEN}http://$DOMAIN/admin${NC}"
echo -e "🔧 API Health: ${GREEN}http://$DOMAIN/health${NC}"
echo -e "📁 App Directory: ${YELLOW}$APP_DIR${NC}"
echo -e "👥 App User: ${YELLOW}$APP_USER${NC}"
echo ""
echo -e "${BLUE}🔑 ADMIN LOGIN CREDENTIALS:${NC}"
echo -e "Email: ${YELLOW}admin@logistics.com${NC}"
echo -e "Password: ${YELLOW}[See .env.production file]${NC}"
echo ""
echo -e "${BLUE}🔧 MANAGEMENT COMMANDS:${NC}"
echo -e "View PM2 logs: ${YELLOW}sudo -u $APP_USER pm2 logs${NC}"
echo -e "Restart backend: ${YELLOW}sudo -u $APP_USER pm2 restart tik-workshop-backend${NC}"
echo -e "Stop backend: ${YELLOW}sudo -u $APP_USER pm2 stop tik-workshop-backend${NC}"
echo -e "Reload Nginx: ${YELLOW}sudo systemctl reload nginx${NC}"
echo -e "View Nginx logs: ${YELLOW}sudo tail -f /var/log/nginx/error.log${NC}"
echo ""
echo -e "${GREEN}🚀 Your TikTok Workshop site is now live!${NC}"
echo -e "${BLUE}Visit: http://$DOMAIN${NC}"
