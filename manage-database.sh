#!/bin/bash

# 🗄️ Database Connection Monitor & Management Script
# Monitors and manages PostgreSQL connections to prevent max_connections issues

echo "🗄️ Database Connection Management"
echo "================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_DIR="/var/www/tik-workshop/backend"

# Function to check database connections
check_db_connections() {
    echo -e "${BLUE}📊 Checking Database Connection Status${NC}"
    echo "======================================"
    
    if [ -f "$APP_DIR/.env" ]; then
        # Extract database info from .env
        DB_URL=$(grep "DATABASE_URL=" "$APP_DIR/.env" | cut -d'=' -f2- | tr -d '"')
        DB_HOST=$(echo "$DB_URL" | sed -n 's/.*@\([^:]*\).*/\1/p')
        DB_PORT=$(echo "$DB_URL" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
        DB_NAME=$(echo "$DB_URL" | sed -n 's/.*\/\([^?]*\).*/\1/p')
        
        echo "Database Host: $DB_HOST"
        echo "Database Port: $DB_PORT" 
        echo "Database Name: $DB_NAME"
        echo ""
        
        # Test connection using Node.js
        cd "$APP_DIR"
        node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();

async function checkConnections() {
  try {
    // Test basic connection
    await prisma.\$connect();
    console.log('✅ Database connection successful');
    
    // Query connection info if possible
    try {
      const result = await prisma.\$queryRaw\`
        SELECT count(*) as active_connections 
        FROM pg_stat_activity 
        WHERE state = 'active'
      \`;
      console.log('📊 Active connections:', result[0].active_connections.toString());
    } catch (e) {
      console.log('⚠️  Cannot query connection count (limited permissions)');
    }
    
    await prisma.\$disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
}

checkConnections();
        "
    else
        echo -e "${RED}❌ .env file not found in $APP_DIR${NC}"
    fi
}

# Function to optimize PM2 configuration for database connections
optimize_pm2_config() {
    echo ""
    echo -e "${BLUE}⚙️ Optimizing PM2 Configuration${NC}"
    echo "==============================="
    
    cd "$APP_DIR"
    
    # Create optimized ecosystem.config.js
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'tik-workshop-backend',
      script: 'index.js',
      instances: 2, // Limit instances to prevent too many connections
      exec_mode: 'cluster',
      max_memory_restart: '500M',
      node_args: '--max-old-space-size=512',
      env: {
        NODE_ENV: 'production',
        PORT: 4000
      },
      // Database connection optimization
      kill_timeout: 10000, // Allow time for graceful shutdown
      listen_timeout: 10000,
      // Auto restart settings
      max_restarts: 5,
      min_uptime: '10s',
      // Logging
      log_file: './logs/combined.log',
      out_file: './logs/out.log',
      error_file: './logs/error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ]
};
EOF
    
    # Create logs directory
    mkdir -p logs
    
    echo -e "${GREEN}✅ Created optimized PM2 configuration${NC}"
    echo "   - Limited to 2 instances to reduce connection usage"
    echo "   - Added graceful shutdown handling"  
    echo "   - Memory limits to prevent resource exhaustion"
}

# Function to restart with optimized settings
restart_with_optimization() {
    echo ""
    echo -e "${BLUE}🔄 Restarting with Optimized Settings${NC}"
    echo "====================================="
    
    cd "$APP_DIR"
    
    # Stop all PM2 processes
    echo "Stopping existing processes..."
    pm2 delete all 2>/dev/null || true
    
    # Wait for connections to close
    sleep 5
    
    # Start with ecosystem config
    echo "Starting with optimized configuration..."
    pm2 start ecosystem.config.js
    pm2 save
    
    # Check status
    pm2 status
    
    echo -e "${GREEN}✅ Backend restarted with database optimization${NC}"
}

# Function to monitor connections continuously
monitor_connections() {
    echo ""
    echo -e "${BLUE}👁️ Starting Connection Monitor${NC}"
    echo "=============================="
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    while true; do
        # Check PM2 status
        echo -e "${YELLOW}$(date): Checking system status...${NC}"
        
        # Count Node.js processes
        NODE_PROCESSES=$(pgrep -f "node.*index.js" | wc -l)
        echo "Node.js processes running: $NODE_PROCESSES"
        
        # Check memory usage
        MEMORY_USAGE=$(ps aux | grep "node.*index.js" | grep -v grep | awk '{sum += $4} END {print sum}')
        echo "Total memory usage: ${MEMORY_USAGE:-0}%"
        
        # Test database connection
        cd "$APP_DIR"
        if timeout 10 node -e "
const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();
prisma.user.count().then(() => {
  console.log('✅ DB connection OK');
  process.exit(0);
}).catch(() => {
  console.log('❌ DB connection failed');  
  process.exit(1);
}).finally(() => prisma.\$disconnect());
        " 2>/dev/null; then
            echo "Database: Connected"
        else
            echo "Database: Connection issues detected"
            echo -e "${RED}🚨 Database connection problem - consider restarting${NC}"
        fi
        
        echo "---"
        sleep 30
    done
}

# Main menu
echo -e "${YELLOW}Database Connection Management Options:${NC}"
echo "1. Check current connection status"
echo "2. Optimize PM2 configuration"  
echo "3. Restart with optimizations"
echo "4. Monitor connections (continuous)"
echo "5. Run all optimizations (recommended)"
echo ""

if [ -z "$1" ]; then
    echo "Usage: $0 [1-5] or run without arguments for interactive mode"
    echo ""
    read -p "Select option (1-5): " choice
else
    choice=$1
fi

case $choice in
    1)
        check_db_connections
        ;;
    2)
        optimize_pm2_config
        ;;
    3)
        restart_with_optimization
        ;;
    4)
        monitor_connections
        ;;
    5)
        echo -e "${BLUE}🚀 Running Full Database Optimization${NC}"
        echo "===================================="
        check_db_connections
        optimize_pm2_config  
        restart_with_optimization
        echo ""
        echo -e "${GREEN}🎉 Database optimization complete!${NC}"
        echo ""
        echo "To monitor ongoing connections, run:"
        echo "$0 4"
        ;;
    *)
        echo -e "${RED}Invalid option. Please select 1-5.${NC}"
        exit 1
        ;;
esac
