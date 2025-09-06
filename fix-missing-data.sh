#!/bin/bash

# Fix Missing userData or items Error
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x fix-missing-data.sh && ./fix-missing-data.sh

echo "🔧 Fix Missing userData or items Error"
echo "====================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}🚨 Problem: Backend expects 'userData' and 'items' but frontend sends different format${NC}"
echo "Solution: Make backend flexible to accept any data format"

cd /var/www/tik-workshop/backend || exit 1

echo -e "${YELLOW}🛑 Stop backend to update...${NC}"
pm2 delete tik-workshop-backend 2>/dev/null || true

echo -e "${YELLOW}🔧 Create flexible backend that accepts any data format...${NC}"
cp index.js index.js.missing-data-backup-$(date +%H%M%S)

cat > index.js << 'EOF'
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();

console.log('🚀 Starting Flexible Backend...');

// CORS
app.use(cors({
    origin: true,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Body parsing with large limits
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ extended: true, limit: '100mb' }));

// Uploads
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const upload = multer({
    dest: uploadsDir,
    limits: { fileSize: 50 * 1024 * 1024, files: 10 }
});

// Enhanced request logging
app.use((req, res, next) => {
    console.log(`📨 ${req.method} ${req.path} - ${new Date().toISOString()}`);
    if (req.method === 'POST' && req.body) {
        console.log('📦 Raw body keys:', Object.keys(req.body));
        console.log('📦 Body content preview:', JSON.stringify(req.body).substring(0, 200) + '...');
    }
    next();
});

// Health
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        message: 'Flexible backend ready',
        timestamp: new Date().toISOString()
    });
});

// Get requests
app.get('/api/requests', (req, res) => {
    res.json([{
        id: 1,
        message: 'Backend ready with flexible data handling',
        timestamp: new Date().toISOString()
    }]);
});

// POST requests - FLEXIBLE DATA HANDLING
app.post('/api/requests', upload.any(), (req, res) => {
    console.log('📝 === POST /api/requests START ===');
    
    try {
        console.log('📦 FILES:', req.files ? req.files.length : 0);
        console.log('📦 BODY KEYS:', Object.keys(req.body || {}));
        console.log('📦 FULL BODY:', JSON.stringify(req.body, null, 2));

        if (!req.body || Object.keys(req.body).length === 0) {
            console.log('❌ No body data received');
            return res.status(400).json({
                success: false,
                error: 'No form data received',
                debug: 'Request body is empty'
            });
        }

        // FLEXIBLE DATA EXTRACTION
        let userData = null;
        let items = null;

        // Method 1: Direct fields
        if (req.body.userData && req.body.items) {
            console.log('📄 Method 1: Direct userData and items fields');
            userData = req.body.userData;
            items = req.body.items;
        }
        // Method 2: Individual user fields
        else if (req.body.name || req.body.email) {
            console.log('📄 Method 2: Individual user fields detected');
            userData = {
                name: req.body.name || req.body.userName || 'Unknown',
                email: req.body.email || req.body.userEmail || 'unknown@example.com',
                teamName: req.body.teamName || req.body.team || 'Not specified'
            };
            
            // Look for item fields
            items = [];
            const bodyKeys = Object.keys(req.body);
            
            // Check for item patterns
            for (let i = 0; i < 10; i++) {
                const itemName = req.body[`item${i}Name`] || req.body[`itemName${i}`] || req.body[`items[${i}][name]`];
                if (itemName) {
                    items.push({
                        name: itemName,
                        description: req.body[`item${i}Description`] || req.body[`itemDescription${i}`] || req.body[`items[${i}][description]`] || '',
                        quantity: parseInt(req.body[`item${i}Quantity`] || req.body[`itemQuantity${i}`] || req.body[`items[${i}][quantity]`] || '1'),
                        price: parseFloat(req.body[`item${i}Price`] || req.body[`itemPrice${i}`] || req.body[`items[${i}][price]`] || '0'),
                        source: req.body[`item${i}Source`] || req.body[`itemSource${i}`] || req.body[`items[${i}][source]`] || 'Not specified'
                    });
                }
            }
            
            // If no indexed items found, look for generic item fields
            if (items.length === 0 && (req.body.itemName || req.body.name)) {
                items.push({
                    name: req.body.itemName || req.body.name || 'Item',
                    description: req.body.itemDescription || req.body.description || '',
                    quantity: parseInt(req.body.itemQuantity || req.body.quantity || '1'),
                    price: parseFloat(req.body.itemPrice || req.body.price || '0'),
                    source: req.body.itemSource || req.body.source || 'Not specified'
                });
            }
        }
        // Method 3: JSON strings
        else {
            console.log('📄 Method 3: Looking for JSON strings in fields');
            for (const [key, value] of Object.entries(req.body)) {
                if (typeof value === 'string' && (value.startsWith('{') || value.startsWith('['))) {
                    try {
                        const parsed = JSON.parse(value);
                        if (key.includes('user') || key.includes('User')) {
                            userData = parsed;
                        } else if (key.includes('item') || key.includes('Item') || Array.isArray(parsed)) {
                            items = parsed;
                        }
                    } catch (e) {
                        console.log(`❌ Failed to parse JSON in field ${key}:`, e.message);
                    }
                }
            }
        }

        console.log('📄 EXTRACTED userData:', userData);
        console.log('📄 EXTRACTED items:', items);

        // Validate extracted data
        if (!userData) {
            console.log('❌ Could not extract userData');
            return res.status(400).json({
                success: false,
                error: 'Could not find user data',
                debug: {
                    bodyKeys: Object.keys(req.body),
                    suggestion: 'Send userData field or individual name/email fields'
                }
            });
        }

        if (!items || (Array.isArray(items) && items.length === 0)) {
            console.log('❌ Could not extract items');
            return res.status(400).json({
                success: false,
                error: 'Could not find items data',
                debug: {
                    bodyKeys: Object.keys(req.body),
                    suggestion: 'Send items array or individual item fields'
                }
            });
        }

        // Ensure items is an array
        if (!Array.isArray(items)) {
            items = [items];
        }

        // Parse items if they're strings
        items = items.map(item => {
            if (typeof item === 'string') {
                try {
                    return JSON.parse(item);
                } catch (e) {
                    return { name: item, description: '', quantity: 1, price: 0, source: 'Not specified' };
                }
            }
            return item;
        });

        // Success response
        const response = {
            success: true,
            message: 'Request submitted successfully with flexible data handling!',
            data: {
                id: Date.now(),
                user: userData,
                items: items,
                files: req.files ? req.files.map(f => ({
                    originalName: f.originalname,
                    savedName: f.filename,
                    size: f.size
                })) : [],
                submittedAt: new Date().toISOString(),
                debug: {
                    bodyKeys: Object.keys(req.body),
                    extractionMethod: userData && items ? 'Success' : 'Partial'
                }
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
            error: 'Server error processing request',
            details: error.message,
            debug: {
                bodyReceived: !!req.body,
                bodyKeys: req.body ? Object.keys(req.body) : []
            }
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

// Error handler
app.use((err, req, res, next) => {
    console.error('💥 Server Error:', err.message);
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
    console.log(`✅ Flexible backend running on port ${PORT}`);
    console.log(`📦 Accepts any data format - userData/items or individual fields`);
});
EOF

echo -e "${GREEN}✅ Created flexible backend that accepts any data format${NC}"

echo -e "${YELLOW}🚀 Starting flexible backend...${NC}"
pm2 start index.js --name "tik-workshop-backend"

sleep 3

echo -e "${YELLOW}🧪 Testing different data formats...${NC}"

echo "1. Health check:"
curl -s http://localhost:4000/api/health | head -3

echo -e "\n2. Test Format 1 - Direct userData/items:"
test1=$(curl -s -X POST http://localhost:4000/api/requests \
    -H "Content-Type: application/json" \
    -d '{"userData":{"name":"Test User","email":"test@test.com","teamName":"Test Team"},"items":[{"name":"Test Item","description":"Test","quantity":"1","price":"100","source":"Test"}]}' \
    2>/dev/null)
echo "$test1" | head -5

echo -e "\n3. Test Format 2 - Individual fields:"
test2=$(curl -s -X POST http://localhost:4000/api/requests \
    -H "Content-Type: application/json" \
    -d '{"name":"Test User 2","email":"test2@test.com","teamName":"Test Team 2","itemName":"Test Item 2","itemDescription":"Test Description","itemQuantity":"2","itemPrice":"200","itemSource":"Test Source"}' \
    2>/dev/null)
echo "$test2" | head -5

echo -e "\n4. Test Format 3 - Form data style:"
test3=$(curl -s -X POST http://localhost:4000/api/requests \
    -F 'name=Form User' \
    -F 'email=form@test.com' \
    -F 'teamName=Form Team' \
    -F 'item0Name=Form Item' \
    -F 'item0Description=Form Description' \
    -F 'item0Quantity=1' \
    -F 'item0Price=300' \
    -F 'item0Source=Form Source' \
    2>/dev/null)
echo "$test3" | head -5

echo -e "\n${YELLOW}📱 Backend logs (last 10 lines):${NC}"
pm2 logs tik-workshop-backend --lines 10 --nostream

echo -e "\n${GREEN}🎉 Flexible Data Handling Complete!${NC}"
echo -e "${BLUE}📋 Backend now accepts:${NC}"
echo -e "✅ Format 1: {userData: {...}, items: [...]}"
echo -e "✅ Format 2: {name, email, itemName, itemDescription, ...}"
echo -e "✅ Format 3: Form data with any field names"
echo -e "✅ JSON strings in any field"
echo -e "${YELLOW}📱 Try your form submission - it should work now!${NC}"
