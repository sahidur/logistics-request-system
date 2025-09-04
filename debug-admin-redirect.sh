#!/bin/bash

# Debug Admin Redirect Issue
echo "🔍 Debugging /admin redirect to wdp.joycalls.com"
echo "================================================="

SERVER_IP="139.59.122.235"

echo -e "\n1. Testing direct server responses..."
echo "Testing root path:"
curl -I "http://$SERVER_IP" 2>/dev/null | head -n 5

echo -e "\nTesting /admin path:"
curl -I "http://$SERVER_IP/admin" 2>/dev/null | head -n 10

echo -e "\nTesting with verbose output:"
curl -v "http://$SERVER_IP/admin" 2>&1 | head -n 20

echo -e "\n2. Checking DNS resolution..."
nslookup $SERVER_IP

echo -e "\n3. Testing if it's a redirect loop..."
curl -L -I "http://$SERVER_IP/admin" 2>/dev/null | grep -E "(HTTP|Location|Server)"

echo -e "\n4. Testing different paths..."
echo "Testing /api/health:"
curl -I "http://$SERVER_IP:4000/health" 2>/dev/null | head -n 3

echo -e "\nTesting main page content:"
curl -s "http://$SERVER_IP" | head -n 10

echo -e "\nTesting admin page content:"
curl -s "http://$SERVER_IP/admin" | head -n 10

echo -e "\n5. Checking if there are multiple nginx configs..."
echo "This script helps identify the redirect source."
echo "Run this on your server to check nginx configs:"
echo "sudo nginx -T | grep -A 5 -B 5 'wdp.joycalls.com'"
echo "sudo nginx -T | grep -A 5 -B 5 'redirect'"
echo "sudo find /etc/nginx -name '*.conf' -exec grep -l 'wdp.joycalls.com' {} +"
