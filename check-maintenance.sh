#!/bin/bash

# Quick Check - What's Being Served
echo "🔍 Checking what your website is serving..."

SERVER_IP="152.42.229.232"
DOMAIN="https://tiktok.somadhanhobe.com"

echo ""
echo "🌐 Testing website content:"
echo "================================"

echo ""
echo "📄 First 10 lines of homepage:"
curl -s "$DOMAIN" | head -10

echo ""
echo "🔍 Checking for maintenance keywords:"
if curl -s "$DOMAIN" | grep -qi "maintenance\|configured\|shortly"; then
    echo "❌ CONFIRMED: Maintenance page is being served"
    echo ""
    echo "🛠️ SOLUTION:"
    echo "1. Copy script to server:"
    echo "   scp replace-maintenance-with-app.sh root@$SERVER_IP:~/"
    echo ""
    echo "2. SSH to server and run:"
    echo "   ssh root@$SERVER_IP"
    echo "   chmod +x replace-maintenance-with-app.sh"
    echo "   ./replace-maintenance-with-app.sh"
else
    echo "✅ No maintenance page detected"
    echo "✅ React app should be loading properly"
fi

echo ""
echo "🔧 Backend API status:"
curl -s "http://$SERVER_IP:4000/health" 2>/dev/null || echo "❌ Backend not responding"
