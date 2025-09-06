# 🚀 TikTok Workshop Logistics - Complete Production Deployment Guide

This guide provides **one-command deployment** for the complete TikTok Learning Sharing Workshop logistics system on domain **tiktok.somadhanhobe.ccurl http://152.42.229.232:4000/health

# Test frontend
curl -I http://152.42.229.232

# Test admin route
curl -I http://152.42.229.232/adminth automatic SSL.

## ⚠️ **Security Notice**
Ensure your `.env.production` files contain your actual database credentials before deployment. The GitHub repository contains placeholder values for security.

## 📋 What Gets Deployed

- ✅ **Frontend**: React SPA with glassmorphism UI
- ✅ **Backend**: Node.js API with PostgreSQL
- ✅ **Admin Panel**: Separate admin dashboard at `/admin`
- ✅ **Database**: DigitalOcean PostgreSQL (pre-configured)
- ✅ **Web Server**: Nginx with proper routing
- ✅ **Process Manager**: PM2 for backend clustering
- ✅ **File Uploads**: Complete upload functionality
- ✅ **Security**: Production headers and configurations

## 🌐 Production URLs

- **Main Website**: `https://tiktok.somadhanhobe.com`
- **Admin Dashboard**: `https://tiktok.somadhanhobe.com/admin`  
- **API Health Check**: `https://tiktok.somadhanhobe.com/api/health`

## � Admin Credentials

```
Email: admin@logistics.com
Password: TikTok_Admin_2025_Server_148!
```

## � **Working Directory Location**

Your TikTok Workshop files should be located at: **`/opt/tik-workshop`**

**Quick Navigation Commands:**
```bash
# Go to workshop directory
cd /opt/tik-workshop

# Update code from GitHub
git pull origin main

# List all files
ls -la

# View deployment scripts
ls -la *.sh
```

**If you can't find your workshop directory:**
```bash
# Run the directory finder
curl -s https://raw.githubusercontent.com/sahidur/logistics-request-system/main/find-workshop.sh | bash
```

## �🚀 One-Command Deployment

### Step 1: Connect to Your Server
```bash
ssh root@152.42.229.232
```

### Step 2: Find or Create Workshop Directory
```bash
# Option A: If you already cloned before, find the directory
curl -s https://raw.githubusercontent.com/sahidur/logistics-request-system/main/find-workshop.sh | bash

# Option B: Fresh installation to permanent location
git clone https://github.com/sahidur/logistics-request-system.git /opt/tik-workshop
cd /opt/tik-workshop
```

### Step 3: Deploy Application
```bash
chmod +x *.sh
sudo ./deploy-app.sh
```

### Step 4: Verify Deployment
```bash
sudo ./verify-deployment.sh
```

## 📊 Expected Output

After successful deployment, you'll see:
```
🎉 DEPLOYMENT COMPLETE!
===============================================
🌐 Website: https://tiktok.somadhanhobe.com
👤 Admin Panel: https://tiktok.somadhanhobe.com/admin
🔧 API Health: https://tiktok.somadhanhobe.com/api/health
```

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
- **Main App**: `http://152.42.229.232`
- **Admin Login**: `http://152.42.229.232/admin`
- **API Health**: `http://152.42.229.232:4000/health`
- **API Base**: `http://152.42.229.232:4000`

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
   cd /opt/tik-workshop
   curl http://tiktok.somadhanhobe.com/api/health
   curl https://tiktok.somadhanhobe.com
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

1. **Can't access http://152.42.229.232**:
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
curl http://139.59.122.235:4000/health

# Test frontend
curl -I http://139.59.122.235

# Test admin login page
curl -I http://139.59.122.235/admin
```
