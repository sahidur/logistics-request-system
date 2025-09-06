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

// Configure Prisma with optimized database connection settings
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  },
  log: process.env.NODE_ENV === 'development' ? ['query', 'info', 'warn', 'error'] : ['error'],
});

// Connection pool management
const setupDatabaseConnection = async () => {
  try {
    // Test database connection
    await prisma.$connect();
    console.log('✅ Database connected successfully');
    
    // Setup graceful shutdown
    const gracefulShutdown = async (signal) => {
      console.log(`🔄 Received ${signal}. Shutting down gracefully...`);
      try {
        await prisma.$disconnect();
        console.log('✅ Database connections closed');
        process.exit(0);
      } catch (error) {
        console.error('❌ Error during shutdown:', error);
        process.exit(1);
      }
    };
    
    // Handle process termination signals
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));
    process.on('SIGQUIT', () => gracefulShutdown('SIGQUIT'));
    
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    process.exit(1);
  }
};

// Initialize database connection
setupDatabaseConnection();

// Create default admin user if it doesn't exist
const createAdminUser = async () => {
  try {
    const adminEmail = process.env.ADMIN_EMAIL || 'admin@logistics.com';
    const adminPassword = process.env.ADMIN_PASSWORD || 'TikTok_Admin_2025_Server_232!';
    const adminName = process.env.ADMIN_NAME || 'Admin';
    
    // Check if admin user already exists
    const existingAdmin = await prisma.user.findUnique({
      where: { email: adminEmail }
    });
    
    if (!existingAdmin) {
      // Create admin user
      const hashedPassword = await bcrypt.hash(adminPassword, 10);
      const adminUser = await prisma.user.create({
        data: {
          email: adminEmail,
          password: hashedPassword,
          name: adminName,
          teamName: 'Administration',
          role: 'ADMIN'
        }
      });
      console.log('👤 Admin user created successfully:', adminEmail);
    } else {
      console.log('👤 Admin user already exists:', adminEmail);
      // Update admin password to ensure it matches current env
      const hashedPassword = await bcrypt.hash(adminPassword, 10);
      await prisma.user.update({
        where: { email: adminEmail },
        data: { password: hashedPassword }
      });
      console.log('🔑 Admin password updated to match environment variables');
    }
  } catch (error) {
    console.error('❌ Error creating admin user:', error);
  }
};

// Create admin user after database connection
createAdminUser();

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
    origin: [
        'http://localhost:5173', // Development
        'http://localhost:3000', // Alternative dev port
        'https://tiktok.somadhanhobe.com',    // Production domain HTTPS
        'http://tiktok.somadhanhobe.com',     // Production domain HTTP (redirect to HTTPS)
        'http://152.42.229.232',    // Server IP fallback
        'https://152.42.229.232'    // Server IP HTTPS fallback
    ],
    credentials: true
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

// API Health check endpoint (for frontend)
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    message: 'TikTok Workshop API is running',
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
    uptime: Math.floor(process.uptime()),
    database: 'Connected'
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
  console.log('🔐 Login attempt for:', email);
  
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    console.log('❌ User not found:', email);
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  console.log('👤 User found:', user.email, 'Role:', user.role);
  const passwordMatch = await bcrypt.compare(password, user.password);
  console.log('🔑 Password match:', passwordMatch);
  
  if (!passwordMatch) {
    console.log('❌ Password mismatch for:', email);
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, { expiresIn: '1d' });
  console.log('✅ Login successful for:', email);
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
