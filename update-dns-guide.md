# 🌐 DNS Update Guide - Fix Domain Access

## Problem
- ✅ Website works: http://146.190.106.123
- ❌ Domain doesn't work: http://tiktok.somadhanhobe.com
- 🔍 DNS points to old IP: 139.59.122.235

## Solution: Update DNS Records

### Step 1: Access Your Domain DNS Settings

**Common Domain Registrars:**
- **Namecheap**: Login → Domain List → Manage → Advanced DNS
- **GoDaddy**: Login → My Domains → DNS → Manage Zones
- **Cloudflare**: Login → Select Domain → DNS → Records
- **DigitalOcean**: Control Panel → Networking → Domains

### Step 2: Update A Record

**Current Record (WRONG):**
```
Type: A
Name: tiktok
Value: 139.59.122.235
TTL: 300
```

**New Record (CORRECT):**
```
Type: A
Name: tiktok
Value: 146.190.106.123
TTL: 300
```

### Step 3: Add www Subdomain (Optional)

**Add this record too:**
```
Type: A
Name: www.tiktok
Value: 146.190.106.123
TTL: 300
```

### Step 4: Wait for Propagation

- **DNS propagation time**: 5-60 minutes
- **Check progress**: Use online tools like dnschecker.org

### Step 5: Verify

**Test commands:**
```bash
# Should show: 146.190.106.123
nslookup tiktok.somadhanhobe.com

# Should show: 146.190.106.123
dig tiktok.somadhanhobe.com A
```

## Alternative: Use IP Until DNS Updates

While waiting for DNS propagation, you can:
1. Access via IP: http://146.190.106.123
2. Add to hosts file temporarily (local testing)

### Temporary Hosts File Entry
**On Windows:** `C:\Windows\System32\drivers\etc\hosts`
**On Mac/Linux:** `/etc/hosts`

Add this line:
```
146.190.106.123 tiktok.somadhanhobe.com
```

## SSL Certificate Update

After DNS is fixed, you may need to regenerate SSL certificate:

```bash
# On your server (146.190.106.123)
sudo certbot delete --cert-name tiktok.somadhanhobe.com
sudo certbot --nginx -d tiktok.somadhanhobe.com
```

## Verification Checklist

- [ ] DNS A record updated to 146.190.106.123
- [ ] Domain resolves correctly: `nslookup tiktok.somadhanhobe.com`
- [ ] Website loads: http://tiktok.somadhanhobe.com
- [ ] Admin panel works: http://tiktok.somadhanhobe.com/admin
- [ ] SSL certificate renewed (if needed)

## Need Help?

1. **Check DNS propagation**: https://dnschecker.org
2. **Test DNS resolution**: `nslookup tiktok.somadhanhobe.com`
3. **Contact domain provider** if you can't find DNS settings

---

**Current Status:**
- ✅ Server: 146.190.106.123 (Working)
- ❌ DNS: Points to 139.59.122.235 (Needs Update)
- 🎯 Goal: Update DNS to point to 146.190.106.123
