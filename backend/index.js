const express = require('express');
const cors = require('cors');
const multer = require('multer');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('./generated/prisma');
const path = require('path');
const fs = require('fs');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const prisma = new PrismaClient();

// Environment variables with defaults
const PORT = process.env.PORT || 4000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-key';
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:5173';
const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE) || 10485760; // 10MB
const UPLOAD_DIR = process.env.UPLOAD_DIR || './uploads';

// Ensure upload directory exists
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

console.log(`🚀 Starting server in ${NODE_ENV} mode`);
console.log(`📁 Upload directory: ${UPLOAD_DIR}`);
console.log(`📏 Max file size: ${(MAX_FILE_SIZE / 1024 / 1024).toFixed(1)}MB`);

// Configure multer with environment variables
const upload = multer({ 
  dest: UPLOAD_DIR,
  limits: { fileSize: MAX_FILE_SIZE }
});

// CORS configuration for production
const corsOptions = {
  origin: NODE_ENV === 'production' 
    ? [FRONTEND_URL] 
    : ['http://localhost:5173', 'http://localhost:5174', 'http://localhost:5175', 'http://localhost:5176', 'http://localhost:5177', 'http://localhost:5178'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));

// Production middleware
if (NODE_ENV === 'production') {
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
  }));
  app.use(compression());
  app.use(morgan('combined'));
} else {
  app.use(morgan('dev'));
}

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
    uptime: Math.floor(process.uptime())
  });
});

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Logistics Request Backend API',
    version: '1.0.0',
    endpoints: {
      'POST /api/register': 'Register admin user',
      'POST /api/login': 'Admin login',
      'POST /api/submit': 'Submit logistics request',
      'GET /api/requests': 'Get all requests (admin)',
      'GET /api/export': 'Export requests to Excel (admin)',
      'GET /uploads/:filename': 'Get uploaded file'
    }
  });
});

// Auth middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = (authHeader && authHeader.split(' ')[1]) || req.query.token;
  if (!token) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

// Register admin (for setup only)
app.post('/api/register', async (req, res) => {
  const { email, password, name, teamName } = req.body;
  const hashed = await bcrypt.hash(password, 10);
  try {
    const user = await prisma.user.create({
      data: { email, password: hashed, name, teamName, role: 'ADMIN' },
    });
    res.json({ id: user.id, email: user.email });
  } catch (e) {
    res.status(400).json({ error: 'User already exists' });
  }
});

// Login
app.post('/api/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !(await bcrypt.compare(password, user.password))) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '1d' });
  res.json({ token, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
});

// Submit logistics request
app.post('/api/requests', upload.array('files'), async (req, res) => {
  try {
    console.log('📝 Received request:', req.body);
    console.log('📎 Files received:', req.files?.length || 0);
    
    const { name, email, teamName, items } = req.body;
    
    if (!name || !email || !teamName || !items) {
      throw new Error('Missing required fields: name, email, teamName, or items');
    }
    
    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      console.log('👤 Creating new user:', email);
      user = await prisma.user.create({ data: { email, name, teamName, password: '', role: 'USER' } });
    }
    
    const parsedItems = JSON.parse(items);
    console.log('🎯 Items to create:', parsedItems);
    
    const createdRequest = await prisma.request.create({
      data: {
        userId: user.id,
        items: {
          create: parsedItems.map((item, idx) => ({
            name: item.name,
            description: item.description,
            quantity: parseInt(item.quantity),
            price: parseFloat(item.price),
            sampleFile: req.files[idx] ? req.files[idx].filename : null,
            source: item.source,
          })),
        },
      },
      include: { items: true },
    });
    
    console.log('✅ Request created successfully:', createdRequest.id);
    res.json(createdRequest);
  } catch (e) {
    console.error('❌ Error creating request:', e.message);
    console.error('Stack:', e.stack);
    res.status(400).json({ error: e.message });
  }
});

// Get all requests (admin)
app.get('/api/requests', authenticateToken, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  const requests = await prisma.request.findMany({
    include: { user: true, items: true },
    orderBy: { createdAt: 'desc' },
  });
  res.json(requests);
});

// Download Excel (admin)
app.get('/api/requests/export', authenticateToken, async (req, res) => {
  if (req.user.role !== 'ADMIN') return res.sendStatus(403);
  const ExcelJS = require('exceljs');
  const requests = await prisma.request.findMany({
    include: { user: true, items: true },
    orderBy: { createdAt: 'desc' },
  });
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Requests');
  sheet.columns = [
    { header: 'Request ID', key: 'id', width: 10 },
    { header: 'User Name', key: 'userName', width: 20 },
    { header: 'User Email', key: 'userEmail', width: 25 },
    { header: 'Team', key: 'teamName', width: 20 },
    { header: 'Created At', key: 'createdAt', width: 20 },
    { header: 'Item Name', key: 'itemName', width: 20 },
    { header: 'Description', key: 'description', width: 30 },
    { header: 'Quantity', key: 'quantity', width: 10 },
    { header: 'Price', key: 'price', width: 10 },
    { header: 'Source', key: 'source', width: 20 },
    { header: 'Sample File', key: 'sampleFile', width: 30 },
  ];
  requests.forEach(req => {
    req.items.forEach(item => {
      sheet.addRow({
        id: req.id,
        userName: req.user.name,
        userEmail: req.user.email,
        teamName: req.user.teamName,
        createdAt: req.createdAt,
        itemName: item.name,
        description: item.description,
        quantity: item.quantity,
        price: item.price,
        source: item.source,
        sampleFile: item.sampleFile ? `http://localhost:4000/uploads/${item.sampleFile}` : '',
      });
    });
  });
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename="requests.xlsx"');
  await workbook.xlsx.write(res);
  res.end();
});

// Serve uploaded files
app.get('/api/files/:filename', authenticateToken, (req, res) => {
  const filePath = path.join(__dirname, 'uploads', req.params.filename);
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).send('File not found');
  }
});

app.listen(PORT, () => {
  console.log(`🚀 Backend server running on port ${PORT}`);
  console.log(`🌍 Environment: ${NODE_ENV}`);
  console.log(`📡 CORS allowed origins: ${JSON.stringify(corsOptions.origin)}`);
});
