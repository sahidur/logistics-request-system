module.exports = {
  apps: [{
    name: 'tik-workshop-backend',
    script: 'index.js',
    instances: 2, // Limited instances to prevent too many DB connections (was 'max')
    exec_mode: 'cluster',
    max_memory_restart: '500M', // Reduced from 1G to prevent memory issues
    node_args: '--max-old-space-size=512',
    env: {
      NODE_ENV: 'development',
      PORT: 4000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 4000
    },
    // Database connection optimization
    kill_timeout: 10000, // Allow time for Prisma to disconnect gracefully
    listen_timeout: 10000,
    wait_ready: true,
    // Logging
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    time: true,
    // Restart settings optimized for database connections
    restart_delay: 5000, // Increased delay to allow connections to close
    max_restarts: 5,
    min_uptime: '15s', // Increased to ensure stable startup
    autorestart: true
  }]
};
