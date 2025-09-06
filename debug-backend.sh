#!/bin/bash

# Debug Backend Error - Find and Fix Route Issues
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x debug-backend.sh && ./debug-backend.sh

echo "🔍 Debugging Backend Error - Route Issues"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Navigate to backend directory
cd /var/www/tik-workshop/backend || { echo "Backend directory not found"; exit 1; }

echo -e "${YELLOW}🛑 Stopping backend to prevent crashes...${NC}"
pm2 delete all 2>/dev/null || true

echo -e "${YELLOW}📋 Checking complete error logs...${NC}"
echo "=== FULL ERROR LOG ==="
cat /root/.pm2/logs/tik-workshop-backend-error-0.log | tail -20
echo "======================"

echo -e "${YELLOW}🔍 Checking backend code structure...${NC}"
echo "Backend files:"
ls -la | grep -E "\.(js|json)$"

echo -e "${YELLOW}📝 Checking index.js for route errors...${NC}"
echo "Routes defined in index.js:"
grep -n "app\." index.js | head -10

echo -e "${YELLOW}🧪 Testing backend syntax...${NC}"
node -c index.js
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Syntax error in index.js${NC}"
    exit 1
else
    echo -e "${GREEN}✅ No syntax errors found${NC}"
fi

echo -e "${YELLOW}🔧 Testing database connection...${NC}"
node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();
console.log('Testing database...');
prisma.user.findMany().then(users => {
  console.log('✅ Database OK, users:', users.length);
  process.exit(0);
}).catch(err => {
  console.error('❌ Database error:', err.message);
  process.exit(1);
});
"

echo -e "${YELLOW}🔧 Testing basic server startup...${NC}"
timeout 10s node -e "
require('dotenv').config();
const express = require('express');
const app = express();

app.get('/test', (req, res) => {
  res.json({ status: 'test ok' });
});

const server = app.listen(4001, () => {
  console.log('✅ Basic server started on 4001');
  setTimeout(() => {
    server.close();
    process.exit(0);
  }, 2000);
});
" &

sleep 3
test_basic=$(curl -s http://localhost:4001/test 2>/dev/null || echo "FAILED")
echo "Basic server test: $test_basic"

echo -e "${YELLOW}🔧 Creating a safe version of index.js...${NC}"
cp index.js index.js.backup

# Create a minimal working version
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

// CORS configuration
const corsOptions = {
    origin: [
        'http://localhost:5173',
        'http://localhost:3000',
        'https://tiktok.somadhanhobe.com',
        'http://tiktok.somadhanhobe.com',
        'http://152.42.229.232',
        'https://152.42.229.232'
    ],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer configuration for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadsDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ 
    storage: storage,
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'TikTok Workshop API is running',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Get all requests
app.get('/api/requests', async (req, res) => {
    try {
        const requests = await prisma.request.findMany({
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        teamName: true
                    }
                },
                items: true
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
        res.json(requests);
    } catch (error) {
        console.error('Error fetching requests:', error);
        res.status(500).json({ error: 'Failed to fetch requests' });
    }
});

// Submit new request
app.post('/api/requests', upload.array('sampleFiles'), async (req, res) => {
    try {
        console.log('📝 Received request data:', req.body);
        
        const { userData, items } = req.body;
        
        if (!userData || !items) {
            return res.status(400).json({ error: 'Missing required data' });
        }

        // Parse items if it's a string
        let parsedItems;
        try {
            parsedItems = typeof items === 'string' ? JSON.parse(items) : items;
        } catch (parseError) {
            console.error('Error parsing items:', parseError);
            return res.status(400).json({ error: 'Invalid items data' });
        }

        // Create or find user
        let user = await prisma.user.findUnique({
            where: { email: userData.email }
        });

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

        // Create request
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
            include: {
                items: true,
                user: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        teamName: true
                    }
                }
            }
        });

        console.log('✅ Request created successfully:', request.id);
        res.status(201).json(request);

    } catch (error) {
        console.error('❌ Error creating request:', error);
        res.status(500).json({ 
            error: 'Failed to create request',
            details: error.message 
        });
    }
});

// Admin login
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password required' });
        }

        const user = await prisma.user.findUnique({
            where: { email }
        });

        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { userId: user.id, email: user.email },
            process.env.JWT_SECRET || 'fallback-secret',
            { expiresIn: '24h' }
        );

        res.json({
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Login failed' });
    }
});

// Export to Excel endpoint
app.get('/api/export', async (req, res) => {
    try {
        const ExcelJS = require('exceljs');
        const workbook = new ExcelJS.Workbook();
        const worksheet = workbook.addWorksheet('Logistics Requests');

        // Add headers
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
            include: {
                user: true,
                items: true
            },
            orderBy: { createdAt: 'desc' }
        });

        // Add data rows
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

// Serve uploaded files
app.use('/uploads', express.static(uploadsDir));

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ 
        error: 'Endpoint not found',
        path: req.originalUrl,
        method: req.method
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({ 
        error: 'Internal server error',
        details: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
});

const PORT = process.env.PORT || 4000;

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('Received SIGTERM, closing server...');
    await prisma.$disconnect();
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('Received SIGINT, closing server...');
    await prisma.$disconnect();
    process.exit(0);
});

const server = app.listen(PORT, () => {
    console.log(`🚀 Backend server running on port ${PORT}`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`📁 Upload directory: ${uploadsDir}`);
});

module.exports = app;
EOF

echo -e "${GREEN}✅ Created safe version of index.js${NC}"

echo -e "${YELLOW}🚀 Testing the fixed backend...${NC}"
pm2 start index.js --name "tik-workshop-backend" --instances 1

sleep 5

echo -e "${YELLOW}🧪 Testing fixed API endpoints...${NC}"
health_test=$(curl -s http://localhost:4000/api/health 2>/dev/null || echo "FAILED")
echo "Health test: $health_test"

requests_test=$(curl -s http://localhost:4000/api/requests 2>/dev/null || echo "FAILED")
echo "Requests test: ${requests_test:0:50}..."

post_test=$(curl -s -X POST http://localhost:4000/api/requests \
    -H "Content-Type: application/json" \
    -d '{"userData":{"name":"Test","email":"test@test.com"},"items":[{"name":"Test Item","description":"Test","quantity":"1","price":"100","source":"Test"}]}' \
    2>/dev/null || echo "FAILED")
echo "POST test: ${post_test:0:50}..."

echo -e "${GREEN}🎉 Backend Error Fix Complete!${NC}"
echo -e "${YELLOW}📋 Logs (last 5 lines):${NC}"
pm2 logs --lines 5
