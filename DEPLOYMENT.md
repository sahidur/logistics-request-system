# 🚀 TikTok Workshop Logistics - Complete Production Deployment Guide

This guide provides **one-command deployment** for the complete TikTok Learning Sharing Workshop logistics system on server **134.209.110.148**.

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

- **Main Website**: `http://134.209.110.148`
- **Admin Dashboard**: `http://134.209.110.148/admin`  
- **API Health Check**: `http://134.209.110.148/health`

## � Admin Credentials

```
Email: admin@logistics.com
Password: TikTok_Admin_2025_Server_148!
```

## 🚀 One-Command Deployment

### Step 1: Connect to Your Server
```bash
ssh root@134.209.110.148
```

### Step 2: Clone and Deploy (ONE COMMAND!)
```bash
git clone https://github.com/sahidur/logistics-request-system.git /tmp/tik-workshop && \
cd /tmp/tik-workshop && \
chmod +x *.sh && \
./deploy-system.sh && \
./deploy-app.sh
```

### Step 3: Verify Deployment
```bash
./verify-deployment.sh
```

## 📊 Expected Output

After successful deployment, you'll see:
```
🎉 DEPLOYMENT COMPLETE!
===============================================
🌐 Website: http://134.209.110.148
👤 Admin Panel: http://134.209.110.148/admin
🔧 API Health: http://134.209.110.148/health
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
