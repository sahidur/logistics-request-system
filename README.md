# TikTok Learning Sharing Workshop - Logistics Request System

A modern, full-stack logistics request management system with beautiful UI and comprehensive admin dashboard.

## 🚀 Features

- **Modern UI**: Animated gradient backgrounds with glassmorphism design
- **Logistics Request Form**: Dynamic form with file uploads and BDT currency support
- **Admin Dashboard**: Complete request management with Excel export
- **Secure Authentication**: JWT-based admin authentication
- **File Management**: Sample file uploads with organized storage
- **Responsive Design**: Works perfectly on all devices
- **Production Ready**: Docker support, security headers, and optimizations

## 🛠 Tech Stack

**Frontend:**
- React 18 with Vite
- React Router for navigation
- Modern CSS with animations
- Responsive glassmorphism design

**Backend:**
- Node.js with Express
- PostgreSQL with Prisma ORM
- JWT authentication
- Multer for file uploads
- Excel export functionality

## 📦 Development Setup

### Prerequisites
- Node.js 18+ 
- PostgreSQL database
- npm or yarn

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd tik-workshop
   ```

2. **Backend Setup**
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Update .env with your database URL and secrets
   npx prisma generate
   npx prisma db push
   npm run seed
   npm start
   ```

3. **Frontend Setup**
   ```bash
   cd frontend
   npm install
   cp .env.example .env
   # Update .env with your API URL
   npm run dev
   ```

4. **Access the Application**
   - Frontend: http://localhost:5178
   - Backend API: http://localhost:4000
   - Admin Login: http://localhost:5178/admin

## 🌐 Production Deployment

### Option 1: Quick Deploy Script (Recommended)

For Ubuntu Server deployment:

```bash
# 1. Setup system dependencies
sudo ./deploy-system.sh

# 2. Deploy the application
sudo ./deploy-app.sh
```

### Option 2: Docker Deployment

```bash
# 1. Copy environment file
cp .env.example .env
# Edit .env with your production values

# 2. Build and start services
docker-compose up -d

# 3. Run database migrations
docker-compose exec backend npx prisma db push
docker-compose exec backend npm run seed
```

### Option 3: Manual Deployment

1. **Server Setup**
   ```bash
   # Install Node.js, PostgreSQL, Nginx, PM2
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs postgresql nginx
   sudo npm install -g pm2
   ```

2. **Application Setup**
   ```bash
   # Copy files to server
   scp -r . user@server:/var/www/tik-workshop/
   
   # Install dependencies
   cd /var/www/tik-workshop/backend && npm ci --production
   cd /var/www/tik-workshop/frontend && npm ci && npm run build
   
   # Setup environment
   cp .env.example .env  # Edit with production values
   npx prisma generate && npx prisma db push
   npm run seed
   ```

3. **Process Management**
   ```bash
   # Start with PM2
   cd backend
   pm2 start ecosystem.config.js
   pm2 save && pm2 startup
   ```

4. **Nginx Configuration**
   ```bash
   # Copy nginx config and restart
   sudo cp nginx.conf /etc/nginx/sites-available/tik-workshop
   sudo ln -s /etc/nginx/sites-available/tik-workshop /etc/nginx/sites-enabled/
   sudo nginx -t && sudo systemctl restart nginx
   ```

## 🔧 Environment Configuration

### Backend (.env)
```env
DATABASE_URL="postgresql://user:pass@host:5432/dbname"
NODE_ENV=production
JWT_SECRET=your_secure_secret_key_here
FRONTEND_URL=https://your-domain.com
PORT=4000
ADMIN_EMAIL=admin@logistics.com
ADMIN_PASSWORD=secure_password_123
```

### Frontend (.env)
```env
VITE_API_URL=https://your-domain.com
VITE_APP_TITLE=TikTok Learning Sharing Workshop
```

## 🔐 Security Features

- **Helmet.js**: Security headers and XSS protection
- **CORS**: Configurable cross-origin resource sharing
- **JWT Authentication**: Secure admin access
- **Input Validation**: Form validation and sanitization
- **File Upload Security**: Type and size restrictions
- **Environment Variables**: Secure configuration management

## 📊 Admin Features

- **Request Management**: View, filter, and manage all logistics requests
- **Excel Export**: Export request data with team member details
- **File Access**: View uploaded sample files
- **BDT Currency**: Automatic formatting for Bangladeshi Taka
- **Responsive Dashboard**: Works on all devices
- **Secure Logout**: Proper session management

## 🎨 UI Features

- **Animated Backgrounds**: Beautiful gradient animations
- **Glassmorphism**: Modern transparent glass effects
- **Responsive Design**: Mobile-first approach
- **Loading States**: Smooth loading animations
- **Success/Error Modals**: User feedback with animations
- **Professional Typography**: Clean, readable fonts

## 🚀 Performance Optimizations

- **Frontend**: Vite for fast builds, code splitting, lazy loading
- **Backend**: Compression, caching headers, optimized database queries
- **Production**: Minified assets, gzip compression, CDN-ready
- **Docker**: Multi-stage builds for smaller images

## 📝 API Endpoints

```
POST /api/register     - Register admin user
POST /api/login        - Admin authentication
POST /api/requests     - Submit logistics request
GET  /api/requests     - Get all requests (admin)
GET  /api/export       - Export Excel (admin)
GET  /health          - Health check
```

## 🔧 Management Commands

```bash
# View application logs
pm2 logs

# Restart application
pm2 restart all

# Database operations
npx prisma studio    # Database browser
npx prisma db push   # Apply schema changes
npm run seed         # Create admin user

# Backup database
pg_dump dbname > backup.sql
```

## 🛡️ Security Checklist

- [ ] Update default JWT secret
- [ ] Change admin password
- [ ] Configure CORS origins
- [ ] Set up SSL/HTTPS
- [ ] Configure firewall (UFW)
- [ ] Regular database backups
- [ ] Monitor application logs

## 🎯 Default Credentials

**Admin Login:**
- Email: admin@logistics.com
- Password: admin123

⚠️ **Change these credentials immediately in production!**

## 🆘 Troubleshooting

### Common Issues

1. **Database Connection Error**
   ```bash
   # Check database URL in .env
   # Ensure PostgreSQL is running
   sudo systemctl status postgresql
   ```

2. **Port Already in Use**
   ```bash
   # Kill process on port
   sudo lsof -ti:4000 | xargs kill -9
   ```

3. **Permission Errors**
   ```bash
   # Fix file permissions
   sudo chown -R tikworkshop:tikworkshop /var/www/tik-workshop
   ```

4. **Build Errors**
   ```bash
   # Clear npm cache
   npm cache clean --force
   rm -rf node_modules package-lock.json
   npm install
   ```

## 🤝 Support

For deployment support or issues:
1. Check the logs: `pm2 logs`
2. Verify environment variables
3. Check database connectivity
4. Review nginx error logs: `sudo tail -f /var/log/nginx/error.log`

## 📄 License

MIT License - Feel free to use this project for your events and workshops!

---

**Made with ❤️ for TikTok Learning Sharing Workshop**

🌟 **Production Ready** • 🔐 **Secure** • 🎨 **Modern UI** • 📱 **Responsive** • ⚡ **Fast**

This project is a colorful, animated, and dynamic web application for submitting logistics requests for events. It features a multi-item form, file uploads, PostgreSQL integration, and an admin dashboard for managing requests.

## Tech Stack
- Frontend: React (Vite)
- Backend: Node.js (Express)
- Database: PostgreSQL (via Prisma ORM)

## Features
- Dynamic, animated logistics request form
- Add multiple items per request (name, description, quantity, price, file, source location)
- Basic info: name, email, team name (with predefined and custom options)
- File upload support
- Data saved to remote PostgreSQL database
- Admin login and dashboard
- View/download requests and files, export to Excel

## Setup
1. Install dependencies in both `frontend` and `backend` folders:
   - `cd frontend && npm install`
   - `cd backend && npm install`
2. Configure PostgreSQL connection in `backend/.env` and update Prisma schema as needed.
3. Run database migrations:
   - `cd backend && npx prisma migrate dev`
4. Start backend: `cd backend && node index.js` (or `nodemon`)
5. Start frontend: `cd frontend && npm run dev`

## Development
- Frontend code: `frontend/`
- Backend code: `backend/`
- Prisma schema: `backend/prisma/schema.prisma`

---

Replace any placeholder values as needed for your environment.
