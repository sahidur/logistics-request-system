#!/bin/bash

# Fix Admin Redirect Issue - Server Configuration Script
echo "🔧 Fixing /admin redirect to wdp.joycalls.com"
echo "==============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

echo -e "${YELLOW}Step 1: Checking current nginx configuration...${NC}"
nginx -t

echo -e "\n${YELLOW}Step 2: Backing up current nginx config...${NC}"
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup.$(date +%Y%m%d_%H%M%S)

echo -e "\n${YELLOW}Step 3: Removing any conflicting nginx configs...${NC}"
# Remove any configs that might contain wdp.joycalls.com
find /etc/nginx -name "*.conf" -exec grep -l "wdp.joycalls.com" {} + 2>/dev/null | while read file; do
    echo "Found conflicting config: $file"
    mv "$file" "$file.disabled.$(date +%Y%m%d_%H%M%S)"
done

echo -e "\n${YELLOW}Step 4: Creating clean nginx configuration...${NC}"
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name 139.59.122.235 _;
    root /var/www/html;
    index index.html index.htm;

    # Disable server tokens
    server_tokens off;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json;

    # Backend API proxy
    location /api/ {
        proxy_pass http://localhost:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:4000/health;
        access_log off;
    }

    # Uploads proxy
    location /uploads/ {
        proxy_pass http://localhost:4000/uploads/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # React SPA - Handle all routes including /admin
    location / {
        try_files $uri $uri/ @fallback;
    }
    
    # Fallback for React Router
    location @fallback {
        rewrite ^.*$ /index.html last;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Prevent access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF

echo -e "\n${YELLOW}Step 5: Removing default nginx welcome page...${NC}"
rm -f /var/www/html/index.nginx-debian.html

echo -e "\n${YELLOW}Step 6: Checking for DNS/hosts file issues...${NC}"
# Check if there are any weird host entries
grep -v "^#" /etc/hosts | grep -E "(wdp|joycalls)" && echo "Found suspicious hosts entries!" || echo "Hosts file looks clean"

echo -e "\n${YELLOW}Step 7: Testing nginx configuration...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "\n${YELLOW}Step 8: Restarting nginx...${NC}"
    systemctl restart nginx
    systemctl status nginx --no-pager -l
    
    echo -e "\n${GREEN}✅ Nginx configuration fixed!${NC}"
    
    echo -e "\n${YELLOW}Step 9: Testing the fix...${NC}"
    sleep 2
    
    echo "Testing main page:"
    curl -I http://localhost 2>/dev/null | head -n 3
    
    echo -e "\nTesting /admin:"
    curl -s http://localhost/admin | head -n 5
    
    echo -e "\n${GREEN}✅ Configuration completed!${NC}"
    echo -e "\n${YELLOW}Now test from browser:${NC}"
    echo "Main site: http://139.59.122.235"
    echo "Admin panel: http://139.59.122.235/admin"
    
else
    echo -e "\n${RED}❌ Nginx configuration test failed!${NC}"
    echo "Restoring backup..."
    cp /etc/nginx/sites-available/default.backup.* /etc/nginx/sites-available/default
    nginx -t
    exit 1
fi
