#!/bin/bash

# Fix Nginx Configuration Error
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x fix-nginx-config.sh && ./fix-nginx-config.sh

echo "🔧 Fixing Nginx Configuration Error"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}🛑 Stopping Nginx safely...${NC}"
systemctl stop nginx 2>/dev/null || true

echo -e "${YELLOW}🔍 Checking current Nginx configuration...${NC}"
echo "Main nginx.conf check:"
nginx -t 2>&1 | head -10

echo -e "\nExisting sites-enabled:"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "No sites-enabled directory"

echo -e "\nExisting sites-available:"
ls -la /etc/nginx/sites-available/ 2>/dev/null || echo "No sites-available directory"

echo -e "${YELLOW}🧹 Cleaning up existing configurations...${NC}"
# Remove any conflicting configs
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/tik-workshop
rm -f /etc/nginx/sites-available/tik-workshop

# Backup existing nginx.conf
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup-$(date +%Y%m%d-%H%M%S)

echo -e "${YELLOW}🔧 Creating clean Nginx main configuration...${NC}"
cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 768;
    # multi_accept on;
}

http {
    ##
    # Basic Settings
    ##
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    ##
    # Logging Settings
    ##
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;

    ##
    # Gzip Settings
    ##
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    ##
    # Virtual Host Configs
    ##
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF

echo -e "${YELLOW}🔧 Creating TikTok Workshop site configuration...${NC}"
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/conf.d

cat > /etc/nginx/sites-available/tiktok-workshop << 'EOF'
# TikTok Workshop - Logistics Request System
# Domain: tiktok.somadhanhobe.com
# IP: 152.42.229.232

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=uploads:10m rate=5r/s;

# HTTP Server - Redirect to HTTPS for domain, serve directly for IP
server {
    listen 80;
    listen [::]:80;
    server_name tiktok.somadhanhobe.com 152.42.229.232;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Handle domain requests - redirect to HTTPS
    if ($host = tiktok.somadhanhobe.com) {
        return 301 https://$host$request_uri;
    }

    # Handle IP requests - serve directly
    root /var/www/tik-workshop/frontend/dist;
    index index.html index.htm;

    # Frontend routes
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API proxy
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # File uploads
    location /uploads/ {
        limit_req zone=uploads burst=10 nodelay;
        
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}

# HTTPS Server - Only for domain
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name tiktok.somadhanhobe.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/tiktok.somadhanhobe.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tiktok.somadhanhobe.com/privkey.pem;
    
    # SSL Security
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozTLS:10m;
    ssl_session_tickets off;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    root /var/www/tik-workshop/frontend/dist;
    index index.html index.htm;

    # Frontend routes
    location / {
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API proxy
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    }

    # File uploads
    location /uploads/ {
        limit_req zone=uploads burst=10 nodelay;
        
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo -e "${YELLOW}🔗 Enabling site configuration...${NC}"
ln -sf /etc/nginx/sites-available/tiktok-workshop /etc/nginx/sites-enabled/

echo -e "${YELLOW}🧪 Testing Nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Configuration still has errors${NC}"
    echo -e "${YELLOW}Checking detailed error:${NC}"
    nginx -t 2>&1
    echo -e "${YELLOW}Checking for syntax issues:${NC}"
    cat /etc/nginx/sites-available/tiktok-workshop | nginx -t -c /dev/stdin 2>&1 || true
    exit 1
else
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
fi

echo -e "${YELLOW}🔧 Checking SSL certificates...${NC}"
if [ ! -f "/etc/letsencrypt/live/tiktok.somadhanhobe.com/fullchain.pem" ]; then
    echo -e "${YELLOW}📜 SSL certificates missing, creating temporary config...${NC}"
    
    # Create HTTP-only version first
    cat > /etc/nginx/sites-available/tiktok-workshop-temp << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name tiktok.somadhanhobe.com 152.42.229.232;

    root /var/www/tik-workshop/frontend/dist;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /uploads/ {
        proxy_pass http://127.0.0.1:4000;
    }
}
EOF
    
    ln -sf /etc/nginx/sites-available/tiktok-workshop-temp /etc/nginx/sites-enabled/tiktok-workshop
    
    echo -e "${YELLOW}Getting SSL certificate...${NC}"
    systemctl start nginx
    sleep 2
    
    # Get SSL certificate
    certbot --nginx -d tiktok.somadhanhobe.com --non-interactive --agree-tos --email admin@somadhanhobe.com --redirect
    
    # Switch back to full config
    ln -sf /etc/nginx/sites-available/tiktok-workshop /etc/nginx/sites-enabled/tiktok-workshop
    
    nginx -t && systemctl reload nginx
else
    echo -e "${GREEN}✅ SSL certificates found${NC}"
fi

echo -e "${YELLOW}🚀 Starting Nginx...${NC}"
systemctl start nginx
systemctl enable nginx

echo -e "${YELLOW}🧪 Testing services...${NC}"
echo "Nginx status:"
systemctl status nginx --no-pager -l | head -10

echo -e "\nTesting domain access:"
curl -I http://tiktok.somadhanhobe.com 2>/dev/null | head -3 || echo "Domain not accessible"

echo -e "\nTesting IP access:"
curl -I http://152.42.229.232 2>/dev/null | head -3 || echo "IP not accessible"

echo -e "\nTesting HTTPS:"
curl -I https://tiktok.somadhanhobe.com 2>/dev/null | head -3 || echo "HTTPS not accessible"

echo -e "${GREEN}🎉 Nginx Configuration Fixed!${NC}"
echo -e "${BLUE}📋 Access points:${NC}"
echo -e "- HTTP IP: http://152.42.229.232"
echo -e "- HTTPS Domain: https://tiktok.somadhanhobe.com"
