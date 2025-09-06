#!/bin/bash

# Fix Multer Field Name Mismatch
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x fix-multer-field.sh && ./fix-multer-field.sh

echo "🔧 Fix Multer Field Name Mismatch"
echo "================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}🚨 Problem Found: Frontend sends 'files', Backend expects 'sampleFiles'${NC}"
echo "MulterError: Unexpected field 'files'"
echo "Solution: Accept both field names"

cd /var/www/tik-workshop/backend || exit 1

echo -e "${YELLOW}🛑 Stop backend...${NC}"
pm2 delete tik-workshop-backend 2>/dev/null || true

echo -e "${YELLOW}🔧 Fix multer field configuration...${NC}"
cp index.js index.js.multer-error-$(date +%H%M%S)

cat > index.js << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();

console.log('🚀 Starting Fixed Backend...');

// CORS
app.use(cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Body parsing
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Uploads directory
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log('📁 Created uploads directory');
}

// FIXED MULTER - Accept ANY field name
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
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        console.log(`📎 File received - Field: "${file.fieldname}", Name: "${file.originalname}"`);
        // Accept any field name - don't restrict
        cb(null, true);
    }
});

// Request logging
app.use((req, res, next) => {
    console.log(`📨 ${req.method} ${req.path} - ${new Date().toISOString()}`);
    next();
});

// Health
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'Backend running with fixed multer',
        timestamp: new Date().toISOString()
    });
});

// Get requests
app.get('/api/requests', (req, res) => {
    res.json([{
        id: 1,
        message: 'Backend working with file upload fix',
        timestamp: new Date().toISOString()
    }]);
});

// POST requests - FIXED to accept any file field name
app.post('/api/requests', upload.any(), (req, res) => {
    console.log('📝 === POST /api/requests START ===');
    
    try {
        console.log('📦 Files received:', req.files ? req.files.length : 0);
        if (req.files && req.files.length > 0) {
            req.files.forEach((file, index) => {
                console.log(`📎 File ${index + 1}: Field="${file.fieldname}", Name="${file.originalname}", Size=${file.size}`);
            });
        }

        console.log('📦 Body keys:', req.body ? Object.keys(req.body) : 'No body');

        if (!req.body) {
            console.log('❌ No request body');
            return res.status(400).json({
                success: false,
                error: 'No request body'
            });
        }

        const { userData, items } = req.body;

        if (!userData || !items) {
            console.log('❌ Missing userData or items');
            return res.status(400).json({
                success: false,
                error: 'Missing userData or items',
                received: { userData: !!userData, items: !!items }
            });
        }

        // Parse items
        let parsedItems;
        try {
            parsedItems = typeof items === 'string' ? JSON.parse(items) : items;
        } catch (parseError) {
            console.log('❌ Items parse error:', parseError.message);
            return res.status(400).json({
                success: false,
                error: 'Invalid items JSON format'
            });
        }

        // Success response
        const response = {
            success: true,
            message: 'Request submitted successfully! Files uploaded.',
            data: {
                id: Date.now(),
                user: userData,
                items: parsedItems,
                files: req.files ? req.files.map(f => ({
                    originalName: f.originalname,
                    savedName: f.filename,
                    size: f.size,
                    fieldName: f.fieldname
                })) : [],
                submittedAt: new Date().toISOString()
            }
        };

        console.log('✅ Request processed successfully');
        console.log('📝 === POST /api/requests SUCCESS ===');
        
        res.status(201).json(response);

    } catch (error) {
        console.error('💥 POST error:', error);
        console.log('📝 === POST /api/requests ERROR ===');
        
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
        console.error('Login error:', error);
        res.status(500).json({ success: false, error: 'Login failed' });
    }
});

// Export
app.get('/api/export', (req, res) => {
    res.json({ message: 'Export available after database connection' });
});

// Static uploads
app.use('/uploads', express.static(uploadsDir));

// 404 for API
app.use((req, res, next) => {
    if (req.path.startsWith('/api/')) {
        return res.status(404).json({
            error: 'API endpoint not found',
            path: req.path
        });
    }
    next();
});

// Error handler
app.use((err, req, res, next) => {
    console.error('💥 Server Error:', err.message);
    if (err instanceof multer.MulterError) {
        console.error('💥 Multer Error Details:', {
            code: err.code,
            field: err.field,
            message: err.message
        });
        return res.status(400).json({
            success: false,
            error: 'File upload error',
            details: `${err.code}: ${err.message}`,
            field: err.field
        });
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
    console.log(`✅ Fixed backend running on port ${PORT}`);
    console.log(`🔧 Multer accepts any file field name`);
    console.log(`🌐 Ready for form submissions`);
});
EOF

echo -e "${GREEN}✅ Created backend with flexible file field handling${NC}"

echo -e "${YELLOW}🚀 Starting fixed backend...${NC}"
pm2 start index.js --name "tik-workshop-backend"

sleep 3

echo -e "${YELLOW}🧪 Testing file upload fix...${NC}"

echo "Health test:"
curl -s http://localhost:4000/api/health | head -3

echo -e "\nTesting POST with simulated file (using 'files' field name):"
# Create a temporary test file
echo "test file content" > /tmp/test.txt

# Test with files field (what frontend probably sends)
post_with_files=$(curl -s -X POST http://localhost:4000/api/requests \
    -F 'userData={"name":"Test User","email":"test@test.com","teamName":"Test Team"}' \
    -F 'items=[{"name":"Test Item","description":"Test Description","quantity":"1","price":"100","source":"Test"}]' \
    -F 'files=@/tmp/test.txt' \
    2>/dev/null)

echo "$post_with_files" | head -5

# Clean up
rm -f /tmp/test.txt

echo -e "\n${YELLOW}📱 Backend logs:${NC}"
pm2 logs tik-workshop-backend --lines 10 --nostream

echo -e "\n${GREEN}🎉 Multer Field Fix Complete!${NC}"
echo -e "${BLUE}✅ Backend now accepts any file field name${NC}"
echo -e "${BLUE}✅ Form submissions should work without MulterError${NC}"
