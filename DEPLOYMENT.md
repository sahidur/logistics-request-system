# 🚀 Production Deployment Quick Guide
# Server IP: 134.209.110.148

## 📋 Pre-deployment Checklist

### 1. **Server Requirements**
- Ubuntu 20.04+ Server (IP: 134.209.110.148)
- Node.js 18+ installed
- Nginx installed
- Firewall configured for ports 80 and 4000

### 2. **Security Updates Required**

The production environment is pre-configured for your server. Default values:

```bash
# Already configured in .env.production
JWT_SECRET="TikTok_Workshop_2025_Production_JWT_Secret_134_209_110_148_SecureKey_xyz789"
ADMIN_PASSWORD="TikTok_Admin_2025_Server_148!"
FRONTEND_URL=http://134.209.110.148
```

### 3. **Frontend Environment**

Already configured in `frontend/.env.production`:

```bash
VITE_API_URL=http://134.209.110.148:4000
```

## 🚀 Quick Deployment Commands

### Option 1: Automated Deployment (Recommended)
```bash
# SSH to your server
ssh root@134.209.110.148

# Copy your files to server, then run:
sudo ./deploy-system.sh
sudo ./deploy-app.sh
```

### Option 2: Manual Deployment
```bash
# SSH to your server
ssh root@134.209.110.148

# 1. Copy production environment files
cp .env.production backend/.env
cp frontend/.env.production frontend/.env

# 2. Install backend dependencies
cd backend
npm ci --production
npx prisma generate
npx prisma db push

# 3. Create admin user
npm run seed

# 4. Build frontend
cd ../frontend
npm ci
npm run build

# 5. Start with PM2
cd ../backend
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup

# 6. Configure Nginx
sudo cp ../frontend/nginx.conf /etc/nginx/sites-available/tik-workshop
sudo ln -s /etc/nginx/sites-available/tik-workshop /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

## 🔐 Default Credentials

**Admin Login:**
- Email: `admin@logistics.com`
- Password: `TikTok_Admin_2025_Server_148!`

⚠️ **IMPORTANT**: Change these immediately after first login!

## 🌐 Access URLs

**Your Production URLs:**
- **Main App**: `http://134.209.110.148`
- **Admin Login**: `http://134.209.110.148/admin`
- **API Health**: `http://134.209.110.148:4000/health`
- **API Base**: `http://134.209.110.148:4000`

## 🛡️ Security Notes

1. **Firewall Configuration**:
   ```bash
   sudo ufw allow OpenSSH
   sudo ufw allow 80/tcp
   sudo ufw allow 4000/tcp
   sudo ufw --force enable
   ```

2. **Test Firewall**:
   ```bash
   # Test if ports are accessible
   curl http://134.209.110.148:4000/health
   curl http://134.209.110.148
   ```

3. **Database Security**:
   - Your DigitalOcean database already has SSL enabled
   - Connection string includes `sslmode=require`

## 📊 Monitoring Commands

```bash
# Check application status
pm2 status
pm2 logs

# Check nginx status
sudo systemctl status nginx
sudo nginx -t

# Check if ports are listening
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :4000

# Check database connection
cd backend && node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();
prisma.user.findMany().then(users => {
  console.log('✅ Database connected. Users:', users.length);
  process.exit(0);
}).catch(err => {
  console.error('❌ Database error:', err.message);
  process.exit(1);
});"
```

## 🆘 Troubleshooting

**Common Issues:**

1. **Can't access http://134.209.110.148**:
   ```bash
   sudo systemctl status nginx
   sudo ufw status
   ```

2. **API not working**:
   ```bash
   pm2 logs
   curl http://localhost:4000/health
   ```

3. **Database connection error**:
   ```bash
   # Check if .env file exists and has correct DATABASE_URL
   cat backend/.env | grep DATABASE_URL
   ```

4. **File permissions**:
   ```bash
   sudo chown -R $USER:$USER /var/www/tik-workshop
   ```

**Quick Test Commands**:
```bash
# Test backend directly
curl http://134.209.110.148:4000/health

# Test frontend
curl -I http://134.209.110.148

# Test admin login page
curl -I http://134.209.110.148/admin
```
