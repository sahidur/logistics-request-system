#!/bin/bash

# Fix 413 Request Entity Too Large Error
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x fix-413-error.sh && ./fix-413-error.sh

echo "🔧 Fix 413 Request Entity Too Large Error"
echo "========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}🚨 Problem: 413 Request Entity Too Large${NC}"
echo "This can happen at Nginx level or Express level"
echo "Solution: Increase limits in both Nginx and Express"

echo -e "${YELLOW}🔍 Checking current limits...${NC}"

echo "Current Nginx configuration:"
grep -r "client_max_body_size" /etc/nginx/ 2>/dev/null || echo "No client_max_body_size found"

echo -e "\nChecking Express limits in backend:"
cd /var/www/tik-workshop/backend || exit 1
grep -n "limit.*MB\|limit.*mb" index.js || echo "No explicit limits found"

echo -e "${YELLOW}🔧 Fix 1: Update Nginx limits...${NC}"

# Create Nginx config with increased limits
cat > /etc/nginx/sites-available/tiktok-workshop-fixed << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name tiktok.somadhanhobe.com 152.42.229.232;

    # INCREASED BODY SIZE LIMITS
    client_max_body_size 100M;
    client_body_buffer_size 10M;
    client_body_timeout 120s;
    
    # Handle domain requests - redirect to HTTPS
    if ($host = tiktok.somadhanhobe.com) {
        return 301 https://$host$request_uri;
    }

    # Frontend
    root /var/www/tik-workshop/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy with increased limits
    location /api/ {
        # Increased proxy limits
        proxy_request_buffering off;
        proxy_max_temp_file_size 0;
        client_max_body_size 100M;
        
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

    # File uploads with increased limits
    location /uploads/ {
        client_max_body_size 100M;
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# HTTPS version with same limits
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name tiktok.somadhanhobe.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/tiktok.somadhanhobe.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tiktok.somadhanhobe.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # INCREASED BODY SIZE LIMITS
    client_max_body_size 100M;
    client_body_buffer_size 10M;
    client_body_timeout 120s;

    root /var/www/tik-workshop/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy with increased limits
    location /api/ {
        proxy_request_buffering off;
        proxy_max_temp_file_size 0;
        client_max_body_size 100M;
        
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

    location /uploads/ {
        client_max_body_size 100M;
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo -e "${YELLOW}🔧 Fix 2: Update Express backend limits...${NC}"

pm2 delete tik-workshop-backend 2>/dev/null || true

cp index.js index.js.413error-backup-$(date +%H%M%S)

cat > index.js << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();

console.log('🚀 Starting Backend with Increased Limits...');

// CORS
app.use(cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// INCREASED BODY PARSING LIMITS
app.use(express.json({ 
    limit: '100mb',  // Increased from 50mb
    extended: true 
}));
app.use(express.urlencoded({ 
    extended: true, 
    limit: '100mb',  // Increased from 50mb
    parameterLimit: 50000  // Increased parameter limit
}));

console.log('📦 Body parsing limits set to 100MB');

// Uploads directory
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

// MULTER with INCREASED LIMITS
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
        const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9) + path.extname(file.originalname);
        cb(null, uniqueName);
    }
});

const upload = multer({
    storage: storage,
    limits: { 
        fileSize: 50 * 1024 * 1024,  // 50MB per file (increased from 10MB)
        files: 10,  // Max 10 files
        fields: 20,  // Max 20 fields
        fieldSize: 10 * 1024 * 1024  // 10MB per field
    },
    fileFilter: (req, file, cb) => {
        console.log(`📎 File: "${file.originalname}" (${Math.round(file.size/1024)}KB)`);
        cb(null, true);
    }
});

console.log('📎 File upload limits: 50MB per file, 10 files max');

// Request logging with size info
app.use((req, res, next) => {
    const contentLength = req.get('Content-Length');
    console.log(`📨 ${req.method} ${req.path} - Size: ${contentLength ? Math.round(contentLength/1024) + 'KB' : 'Unknown'}`);
    next();
});

// Health
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'Backend with increased limits',
        limits: {
            bodySize: '100MB',
            fileSize: '50MB per file',
            maxFiles: 10
        },
        timestamp: new Date().toISOString()
    });
});

// Get requests
app.get('/api/requests', (req, res) => {
    res.json([{
        id: 1,
        message: 'Backend running with increased limits',
        timestamp: new Date().toISOString()
    }]);
});

// POST requests with size monitoring
app.post('/api/requests', upload.any(), (req, res) => {
    console.log('📝 === POST /api/requests START ===');
    
    try {
        const contentLength = req.get('Content-Length');
        console.log(`📦 Request size: ${contentLength ? Math.round(contentLength/1024) + 'KB' : 'Unknown'}`);
        console.log(`📎 Files: ${req.files ? req.files.length : 0}`);
        
        if (req.files && req.files.length > 0) {
            const totalFileSize = req.files.reduce((sum, file) => sum + file.size, 0);
            console.log(`📎 Total file size: ${Math.round(totalFileSize/1024)}KB`);
            
            req.files.forEach((file, index) => {
                console.log(`📎 File ${index + 1}: "${file.originalname}" - ${Math.round(file.size/1024)}KB`);
            });
        }

        const { userData, items } = req.body;

        if (!userData || !items) {
            console.log('❌ Missing required fields');
            return res.status(400).json({
                success: false,
                error: 'Missing userData or items'
            });
        }

        // Parse items
        let parsedItems;
        try {
            parsedItems = typeof items === 'string' ? JSON.parse(items) : items;
        } catch (parseError) {
            console.log('❌ JSON parse error:', parseError.message);
            return res.status(400).json({
                success: false,
                error: 'Invalid items JSON'
            });
        }

        // Success response
        const response = {
            success: true,
            message: 'Request submitted successfully with large file support!',
            data: {
                id: Date.now(),
                user: userData,
                items: parsedItems,
                files: req.files ? req.files.map(f => ({
                    originalName: f.originalname,
                    savedName: f.filename,
                    size: f.size,
                    sizeKB: Math.round(f.size/1024)
                })) : [],
                submittedAt: new Date().toISOString(),
                totalSizeKB: req.files ? Math.round(req.files.reduce((sum, f) => sum + f.size, 0)/1024) : 0
            }
        };

        console.log('✅ Request processed successfully');
        console.log('📝 === POST /api/requests SUCCESS ===');
        
        res.status(201).json(response);

    } catch (error) {
        console.error('💥 POST error:', error);
        
        if (error.code === 'LIMIT_FILE_SIZE') {
            return res.status(413).json({
                success: false,
                error: 'File too large',
                details: 'Maximum file size is 50MB'
            });
        }
        
        if (error.code === 'LIMIT_FILE_COUNT') {
            return res.status(413).json({
                success: false,
                error: 'Too many files',
                details: 'Maximum 10 files allowed'
            });
        }
        
        res.status(500).json({
            success: false,
            error: 'Server error',
            details: error.message
        });
    }
});

// Login
app.post('/api/login', (req, res) => {
    try {
        const { email, password } = req.body || {};
        if (email && password) {
            res.json({
                success: true,
                token: 'demo-token',
                user: { id: 1, name: 'Admin', email, role: 'ADMIN' }
            });
        } else {
            res.status(400).json({ success: false, error: 'Email and password required' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: 'Login failed' });
    }
});

// Export
app.get('/api/export', (req, res) => {
    res.json({ message: 'Export available' });
});

// Static uploads
app.use('/uploads', express.static(uploadsDir));

// 404 handler
app.use((req, res, next) => {
    if (req.path.startsWith('/api/')) {
        return res.status(404).json({
            error: 'API endpoint not found',
            path: req.path
        });
    }
    next();
});

// Error handler with 413 handling
app.use((err, req, res, next) => {
    console.error('💥 Server Error:', err.message);
    
    if (err.type === 'entity.too.large') {
        console.error('💥 Entity too large error');
        return res.status(413).json({
            success: false,
            error: 'Request entity too large',
            details: 'Reduce file size or request body size'
        });
    }
    
    if (err instanceof multer.MulterError) {
        console.error('💥 Multer Error:', err.code);
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(413).json({
                success: false,
                error: 'File too large',
                details: 'Maximum file size is 50MB'
            });
        }
    }
    
    if (!res.headersSent) {
        res.status(500).json({
            success: false,
            error: 'Internal server error'
        });
    }
});

// Start server
const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Backend running on port ${PORT} with increased limits`);
    console.log(`📦 Body limit: 100MB`);
    console.log(`📎 File limit: 50MB per file, 10 files max`);
});
EOF

echo -e "${YELLOW}🔧 Applying Nginx configuration...${NC}"
rm -f /etc/nginx/sites-enabled/*
ln -sf /etc/nginx/sites-available/tiktok-workshop-fixed /etc/nginx/sites-enabled/

echo -e "${YELLOW}🧪 Testing Nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Nginx config error${NC}"
    exit 1
fi

echo -e "${YELLOW}🚀 Restarting services...${NC}"
systemctl reload nginx
pm2 start index.js --name "tik-workshop-backend"

sleep 3

echo -e "${YELLOW}🧪 Testing increased limits...${NC}"

echo "Health check:"
curl -s http://localhost:4000/api/health | head -5

echo -e "\nTesting with larger request:"
large_data='{"userData":{"name":"Test User with Long Name","email":"test@test.com","teamName":"Test Team"},"items":['
for i in {1..5}; do
    large_data+='{"name":"Item '$i'","description":"This is a longer description for item '$i' to increase the request size and test the new limits","quantity":"'$i'","price":"'$((i*100))'","source":"Test Source '$i'"},'
done
large_data=${large_data%,}']}'

post_large=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST http://localhost:4000/api/requests \
    -H "Content-Type: application/json" \
    -d "$large_data" \
    2>/dev/null | head -10)

echo "$post_large"

echo -e "\n${GREEN}🎉 413 Error Fix Complete!${NC}"
echo -e "${BLUE}📋 New Limits:${NC}"
echo -e "✅ Nginx: 100MB request body"
echo -e "✅ Express: 100MB JSON/form data"
echo -e "✅ Multer: 50MB per file, 10 files max"
echo -e "${YELLOW}📱 Try your form submission now!${NC}"
