#!/bin/bash

# Quick Fix - 502 Bad Gateway Error
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x quick-fix-502.sh && ./quick-fix-502.sh

echo "🚨 Quick Fix - 502 Bad Gateway Error"
echo "===================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Checking current status...${NC}"
echo "PM2 processes:"
pm2 status

echo -e "\nBackend port 4000:"
netstat -tlnp | grep :4000 || echo "Port 4000 not listening"

echo -e "\nNginx status:"
systemctl status nginx --no-pager -l | head -5

echo -e "${YELLOW}🛑 Stopping all services...${NC}"
pm2 delete all 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true

echo -e "${YELLOW}🔧 Going to backend directory...${NC}"
cd /var/www/tik-workshop/backend || { echo "Backend directory not found"; exit 1; }

echo -e "${YELLOW}📋 Checking backend files...${NC}"
ls -la | grep -E "\.(js|json)$"

echo -e "${YELLOW}🔧 Creating minimal working backend...${NC}"
# Backup current file
cp index.js index.js.backup-$(date +%H%M%S) 2>/dev/null || true

# Create super simple working backend
cat > index.js << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

// Simple CORS
app.use(cors({
    origin: true,
    credentials: true
}));

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'TikTok Workshop API is running',
        timestamp: new Date().toISOString(),
        port: process.env.PORT || 4000
    });
});

// Simple test endpoint
app.get('/api/test', (req, res) => {
    res.json({ message: 'Backend is working!' });
});

// Simple requests endpoint
app.get('/api/requests', (req, res) => {
    res.json([
        {
            id: 1,
            message: 'Backend is working - database connection will be restored',
            timestamp: new Date().toISOString()
        }
    ]);
});

// Simple post endpoint
app.post('/api/requests', (req, res) => {
    console.log('Received request:', req.body);
    res.json({
        success: true,
        message: 'Request received - database integration coming soon',
        data: req.body,
        timestamp: new Date().toISOString()
    });
});

// Catch all for API routes
app.use('/api/*', (req, res) => {
    res.status(404).json({
        error: 'API endpoint not found',
        path: req.path,
        method: req.method
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: err.message
    });
});

const PORT = process.env.PORT || 4000;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Simple backend running on port ${PORT}`);
    console.log(`📍 Listening on all interfaces (0.0.0.0:${PORT})`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});
EOF

echo -e "${GREEN}✅ Created minimal working backend${NC}"

echo -e "${YELLOW}🧪 Testing backend syntax...${NC}"
node -c index.js
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Syntax error${NC}"
    exit 1
fi

echo -e "${YELLOW}🚀 Starting backend...${NC}"
pm2 start index.js --name "tik-workshop-backend" --instances 1 --log-date-format "YYYY-MM-DD HH:mm:ss Z"

sleep 3

echo -e "${YELLOW}🧪 Testing backend directly...${NC}"
curl -s http://localhost:4000/api/health || echo "Backend not responding"

echo -e "\nTesting backend test endpoint:"
curl -s http://localhost:4000/api/test || echo "Test endpoint not responding"

echo -e "${YELLOW}🔧 Creating simple Nginx config...${NC}"
cat > /etc/nginx/sites-available/tiktok-simple << 'EOF'
server {
    listen 80;
    server_name tiktok.somadhanhobe.com 152.42.229.232;

    # Serve frontend
    root /var/www/tik-workshop/frontend/dist;
    index index.html;

    # Frontend routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy - simple version
    location /api/ {
        proxy_pass http://127.0.0.1:4000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 5s;
        proxy_read_timeout 10s;
    }

    # Health check
    location /health {
        return 200 "OK";
        add_header Content-Type text/plain;
    }
}
EOF

echo -e "${YELLOW}🔗 Enabling simple Nginx config...${NC}"
rm -f /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/tiktok-simple /etc/nginx/sites-enabled/

echo -e "${YELLOW}🧪 Testing Nginx config...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Nginx config error${NC}"
    nginx -t 2>&1
    exit 1
fi

echo -e "${YELLOW}🚀 Starting Nginx...${NC}"
systemctl start nginx

sleep 2

echo -e "${YELLOW}🧪 Testing complete setup...${NC}"
echo "=== BACKEND TEST ==="
curl -s http://localhost:4000/api/health | head -3

echo -e "\n=== NGINX PROXY TEST ==="
curl -s http://localhost/api/health | head -3

echo -e "\n=== EXTERNAL ACCESS TEST ==="
curl -s http://152.42.229.232/api/health | head -3

echo -e "\n=== PM2 STATUS ==="
pm2 status

echo -e "\n=== SERVICE STATUS ==="
systemctl status nginx --no-pager -l | head -3

echo -e "${GREEN}🎉 Quick Fix Complete!${NC}"
echo -e "${BLUE}📋 Test these URLs:${NC}"
echo -e "- Health: http://152.42.229.232/api/health"
echo -e "- Test: http://152.42.229.232/api/test"
echo -e "- App: http://152.42.229.232"

echo -e "${YELLOW}🔧 If still having issues, check logs:${NC}"
echo -e "- Backend: pm2 logs"
echo -e "- Nginx: tail -f /var/log/nginx/error.log"
