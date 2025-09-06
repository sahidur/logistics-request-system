#!/bin/bash

# Fix Frontend Build - Deploy Real Application UI
# Run this on your server: ssh root@152.42.229.232
# Then: chmod +x fix-frontend.sh && ./fix-frontend.sh

echo "🎯 Fixing Frontend - Deploying Real Application UI"
echo "=================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Navigate to frontend directory
cd /var/www/tik-workshop/frontend || { echo "Frontend directory not found"; exit 1; }

echo -e "${YELLOW}🧹 Cleaning old build and dependencies...${NC}"
rm -rf dist node_modules package-lock.json .vite

echo -e "${YELLOW}📦 Installing compatible dependencies...${NC}"
cat > package.json << 'EOF'
{
  "name": "frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.8.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.5.0"
  }
}
EOF

npm install

echo -e "${YELLOW}🔧 Creating working Vite config...${NC}"
cat > vite.config.js << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    assetsDir: 'assets'
  }
})
EOF

echo -e "${YELLOW}🔨 Building the real application...${NC}"
npm run build

if [ -d "dist" ] && [ "$(ls -A dist)" ]; then
    echo -e "${GREEN}✅ Real application built successfully!${NC}"
    echo "Build contents:"
    ls -la dist/
    
    # Reload nginx to serve the new build
    echo -e "${YELLOW}🔄 Reloading Nginx...${NC}"
    nginx -t && systemctl reload nginx
    
    echo -e "${GREEN}🎉 Success! Your real application UI is now live!${NC}"
    echo -e "${GREEN}🌐 Visit: http://152.42.229.232${NC}"
    echo -e "${GREEN}🌐 Or: https://tiktok.somadhanhobe.com${NC}"
else
    echo -e "${RED}❌ Build failed. Checking source files...${NC}"
    ls -la src/
fi
