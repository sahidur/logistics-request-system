#!/bin/bash

# Emergency Fix - Domain Access & Route Pattern Error
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x emergency-fix.sh && ./emergency-fix.sh

echo "🚨 Emergency Fix - Domain & Backend Issues"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}🛑 STOPPING ALL SERVICES...${NC}"
pm2 delete all 2>/dev/null || true
systemctl stop nginx 2>/dev/null || true

echo -e "${YELLOW}🔍 Checking DNS resolution...${NC}"
echo "Domain DNS check:"
nslookup tiktok.somadhanhobe.com
echo ""
dig tiktok.somadhanhobe.com
echo ""

echo -e "${YELLOW}🔧 Fixing Backend Route Pattern Error...${NC}"
cd /var/www/tik-workshop/backend || { echo "Backend directory not found"; exit 1; }

# Backup current index.js
cp index.js index.js.broken-$(date +%Y%m%d-%H%M%S)

# Create completely clean index.js without problematic routes
cat > index.js << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('./generated/prisma');
const multer = require('multer');
const path = require('path');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');

const app = express();
const prisma = new PrismaClient();

// Basic middleware
app.use(cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadsDir),
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ 
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 }
});

// ROUTES - Simple and clean
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'TikTok Workshop API is running',
        timestamp: new Date().toISOString()
    });
});

app.get('/api/requests', async (req, res) => {
    try {
        const requests = await prisma.request.findMany({
            include: {
                user: { select: { id: true, name: true, email: true, teamName: true } },
                items: true
            },
            orderBy: { createdAt: 'desc' }
        });
        res.json(requests);
    } catch (error) {
        console.error('Error fetching requests:', error);
        res.status(500).json({ error: 'Failed to fetch requests' });
    }
});

app.post('/api/requests', upload.array('sampleFiles'), async (req, res) => {
    try {
        const { userData, items } = req.body;
        
        if (!userData || !items) {
            return res.status(400).json({ error: 'Missing required data' });
        }

        let parsedItems = typeof items === 'string' ? JSON.parse(items) : items;

        let user = await prisma.user.findUnique({ where: { email: userData.email } });
        
        if (!user) {
            user = await prisma.user.create({
                data: {
                    name: userData.name,
                    email: userData.email,
                    teamName: userData.teamName || 'Not specified',
                    password: await bcrypt.hash('defaultpass', 10)
                }
            });
        }

        const request = await prisma.request.create({
            data: {
                userId: user.id,
                items: {
                    create: parsedItems.map((item, index) => ({
                        name: item.name,
                        description: item.description,
                        quantity: parseInt(item.quantity),
                        price: parseFloat(item.price),
                        source: item.source,
                        sampleFile: req.files && req.files[index] ? req.files[index].filename : null
                    }))
                }
            },
            include: { items: true, user: { select: { id: true, name: true, email: true, teamName: true } } }
        });

        res.status(201).json(request);
    } catch (error) {
        console.error('Error creating request:', error);
        res.status(500).json({ error: 'Failed to create request', details: error.message });
    }
});

app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password required' });
        }

        const user = await prisma.user.findUnique({ where: { email } });
        
        if (!user || !await bcrypt.compare(password, user.password)) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET || 'fallback-secret',
            { expiresIn: '24h' }
        );

        res.json({
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

app.get('/api/export', async (req, res) => {
    try {
        const ExcelJS = require('exceljs');
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Logistics Requests');

        worksheet.columns = [
            { header: 'ID', key: 'id', width: 10 },
            { header: 'User Name', key: 'userName', width: 20 },
            { header: 'Email', key: 'email', width: 25 },
            { header: 'Team', key: 'team', width: 20 },
            { header: 'Item Name', key: 'itemName', width: 25 },
            { header: 'Description', key: 'description', width: 30 },
            { header: 'Quantity', key: 'quantity', width: 10 },
            { header: 'Price (BDT)', key: 'price', width: 15 },
            { header: 'Source', key: 'source', width: 20 },
            { header: 'Sample File', key: 'sampleFile', width: 20 },
            { header: 'Created At', key: 'createdAt', width: 20 }
        ];

        const requests = await prisma.request.findMany({
            include: { user: true, items: true },
            orderBy: { createdAt: 'desc' }
        });

        requests.forEach(request => {
            request.items.forEach(item => {
                worksheet.addRow({
                    id: request.id,
                    userName: request.user.name,
                    email: request.user.email,
                    team: request.user.teamName,
                    itemName: item.name,
                    description: item.description,
                    quantity: item.quantity,
                    price: item.price,
                    source: item.source,
                    sampleFile: item.sampleFile || 'None',
                    createdAt: request.createdAt.toISOString().split('T')[0]
                });
            });
        });

        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', 'attachment; filename=logistics-requests.xlsx');

        await workbook.xlsx.write(res);
        res.end();
    } catch (error) {
        console.error('Export error:', error);
        res.status(500).json({ error: 'Export failed' });
    }
});

// Serve static files
app.use('/uploads', express.static(uploadsDir));

// IMPORTANT: Simple 404 handler - no problematic patterns
app.use((req, res) => {
    res.status(404).json({ 
        error: 'Endpoint not found',
        path: req.originalUrl,
        method: req.method
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
    console.log(`🚀 Backend server running on port ${PORT}`);
});
EOF

echo -e "${GREEN}✅ Created clean backend without problematic routes${NC}"

echo -e "${YELLOW}🔧 Fixing Nginx configuration for domain...${NC}"
cd /var/www/tik-workshop/frontend || exit 1

# Create proper Nginx config
cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name tiktok.somadhanhobe.com 152.42.229.232;

    # Redirect HTTP to HTTPS for domain
    if ($host = tiktok.somadhanhobe.com) {
        return 301 https://$host$request_uri;
    }
    
    # Allow direct IP access over HTTP
    if ($host = 152.42.229.232) {
        root /var/www/tik-workshop/frontend/dist;
        index index.html;
        
        location / {
            try_files $uri $uri/ /index.html;
        }
        
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
        
        location /uploads/ {
            proxy_pass http://localhost:4000/uploads/;
        }
    }
}

server {
    listen 443 ssl http2;
    server_name tiktok.somadhanhobe.com;

    ssl_certificate /etc/letsencrypt/live/tiktok.somadhanhobe.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tiktok.somadhanhobe.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    root /var/www/tik-workshop/frontend/dist;
    index index.html;

    # Frontend
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API routes
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

    # File uploads
    location /uploads/ {
        proxy_pass http://localhost:4000/uploads/;
    }
}
EOF

echo -e "${GREEN}✅ Created proper Nginx configuration${NC}"

echo -e "${YELLOW}🔧 Copying Nginx config to system...${NC}"
cp nginx.conf /etc/nginx/sites-available/tik-workshop
ln -sf /etc/nginx/sites-available/tik-workshop /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo -e "${YELLOW}🧪 Testing Nginx configuration...${NC}"
nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Nginx config error${NC}"
    exit 1
fi

echo -e "${YELLOW}🔧 Checking SSL certificates...${NC}"
if [ ! -f "/etc/letsencrypt/live/tiktok.somadhanhobe.com/fullchain.pem" ]; then
    echo -e "${YELLOW}📜 SSL certificates not found, generating...${NC}"
    certbot --nginx -d tiktok.somadhanhobe.com --non-interactive --agree-tos --email admin@somadhanhobe.com
fi

echo -e "${YELLOW}🚀 Starting services...${NC}"
cd /var/www/tik-workshop/backend

# Start backend
pm2 start index.js --name "tik-workshop-backend" --instances 1
sleep 3

# Start Nginx
systemctl start nginx
systemctl enable nginx

echo -e "${YELLOW}🧪 Testing services...${NC}"
echo "Backend health check:"
curl -s http://localhost:4000/api/health || echo "Backend not responding"

echo -e "\nNginx status:"
systemctl status nginx --no-pager -l

echo -e "\nPM2 status:"
pm2 status

echo -e "${YELLOW}🌐 Testing domain access...${NC}"
echo "HTTP test (should redirect):"
curl -I http://tiktok.somadhanhobe.com 2>/dev/null || echo "Domain not accessible"

echo -e "\nHTTPS test:"
curl -I https://tiktok.somadhanhobe.com 2>/dev/null || echo "HTTPS not accessible"

echo -e "\nIP test:"
curl -I http://152.42.229.232 2>/dev/null || echo "IP not accessible"

echo -e "${GREEN}🎉 Emergency Fix Complete!${NC}"
echo -e "${BLUE}📋 Access points:${NC}"
echo -e "- IP: http://152.42.229.232"
echo -e "- Domain: https://tiktok.somadhanhobe.com"
echo -e "${YELLOW}📱 Check logs: pm2 logs${NC}"
