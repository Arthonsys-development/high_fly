# Custom Domain Setup Guide

This guide will help you map your Flutter web app to a custom domain (e.g., `https://yourdomain.com` or `https://app.yourdomain.com`).

## Prerequisites

1. ✅ Your app is already deployed to Firebase Hosting
2. ✅ You own a domain name (purchased from a registrar like GoDaddy, Namecheap, Google Domains, etc.)
3. ✅ You have access to your domain's DNS settings

## Step-by-Step Instructions

### Step 1: Access Firebase Hosting Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/vistarak-apps/hosting)
2. Navigate to your project: **vistarak-apps**
3. Click on **Hosting** in the left sidebar

### Step 2: Add Custom Domain

1. In the Hosting dashboard, click **"Add custom domain"** button
2. Enter your custom domain (e.g., `yourdomain.com` or `app.yourdomain.com`)
3. Click **Continue**

### Step 3: Verify Domain Ownership

Firebase will provide you with two options:

#### Option A: Add TXT Record (Recommended)
1. Firebase will show you a **TXT record** to add to your DNS
2. Copy the TXT record value (looks like: `firebase=vistarak-apps`)
3. Go to your domain registrar's DNS management panel
4. Add a new TXT record:
   - **Type**: TXT
   - **Name/Host**: `@` (or leave blank for root domain)
   - **Value**: The TXT record value from Firebase
   - **TTL**: 3600 (or default)
5. Save the DNS record
6. Wait 5-10 minutes for DNS propagation
7. Click **"Verify"** in Firebase Console

#### Option B: Add A Record (Alternative)
If TXT verification doesn't work, Firebase will provide A records to add.

### Step 4: Configure DNS Records

After verification, Firebase will provide you with DNS records to add:

#### For Root Domain (yourdomain.com):
Add these records to your DNS:

**A Record:**
- **Type**: A
- **Name**: `@` (or leave blank)
- **Value**: The IP address provided by Firebase (usually `151.101.1.195` or `151.101.65.195`)
- **TTL**: 3600

**AAAA Record (for IPv6):**
- **Type**: AAAA
- **Name**: `@` (or leave blank)
- **Value**: The IPv6 address provided by Firebase
- **TTL**: 3600

#### For Subdomain (app.yourdomain.com):
Add a CNAME record:

**CNAME Record:**
- **Type**: CNAME
- **Name**: `app` (or your subdomain name)
- **Value**: The Firebase hosting URL (e.g., `vistarak-apps.web.app`)
- **TTL**: 3600

### Step 5: SSL Certificate Provisioning

1. After DNS records are added, Firebase will automatically provision an SSL certificate
2. This process takes **15-60 minutes**
3. You'll see the status change from "Pending" to "Active" in Firebase Console
4. Firebase uses Let's Encrypt for free SSL certificates

### Step 6: Wait for Propagation

- DNS changes can take **5 minutes to 48 hours** to propagate globally
- Usually takes **15-30 minutes** for most users
- You can check DNS propagation using: https://www.whatsmydns.net

### Step 7: Verify Your Custom Domain

Once SSL is active:
1. Visit your custom domain in a browser
2. You should see your Flutter web app
3. The URL should show a secure padlock (🔒)

## Common DNS Providers Instructions

### GoDaddy
1. Log in to GoDaddy
2. Go to **My Products** → **DNS**
3. Click **Manage DNS** for your domain
4. Click **Add** to add new records
5. Enter the values provided by Firebase
6. Save

### Namecheap
1. Log in to Namecheap
2. Go to **Domain List** → Select your domain → **Manage**
3. Go to **Advanced DNS** tab
4. Click **Add New Record**
5. Enter the values provided by Firebase
6. Save

### Google Domains
1. Log in to Google Domains
2. Select your domain
3. Go to **DNS** section
4. Click **Custom records**
5. Add the records provided by Firebase
6. Save

### Cloudflare
1. Log in to Cloudflare
2. Select your domain
3. Go to **DNS** section
4. Click **Add record**
5. Enter the values provided by Firebase
6. **Important**: Set proxy status to **DNS only** (gray cloud) initially
7. Save

## Troubleshooting

### Domain Verification Fails

**Problem**: Firebase can't verify your domain

**Solutions**:
- Wait 10-15 minutes after adding DNS records
- Verify DNS records are correct using: `dig TXT yourdomain.com` (Linux/Mac) or `nslookup -type=TXT yourdomain.com` (Windows)
- Ensure there are no typos in the DNS record values
- Check that your DNS provider has saved the records

### SSL Certificate Not Provisioning

**Problem**: SSL certificate stays in "Pending" status

**Solutions**:
- Ensure DNS records are correctly configured
- Wait up to 60 minutes (Firebase needs time to verify)
- Check that your domain is accessible via HTTP first
- Verify DNS propagation is complete

### Domain Not Loading

**Problem**: Custom domain shows error or doesn't load

**Solutions**:
- Verify DNS records are correct
- Check DNS propagation: https://www.whatsmydns.net
- Ensure SSL certificate is active in Firebase Console
- Clear browser cache and try again
- Check Firebase Console for any error messages

### Subdomain Not Working

**Problem**: `app.yourdomain.com` doesn't work

**Solutions**:
- Verify CNAME record is correctly set
- Ensure CNAME points to Firebase hosting URL (e.g., `vistarak-apps.web.app`)
- Wait for DNS propagation
- Check that subdomain is added in Firebase Console

## Testing Your Setup

### Check DNS Records

**On Mac/Linux:**
```bash
# Check A record
dig yourdomain.com

# Check CNAME record
dig app.yourdomain.com

# Check TXT record
dig TXT yourdomain.com
```

**On Windows:**
```bash
# Check A record
nslookup yourdomain.com

# Check CNAME record
nslookup app.yourdomain.com

# Check TXT record
nslookup -type=TXT yourdomain.com
```

### Verify SSL Certificate

1. Visit your custom domain
2. Click the padlock icon in the browser
3. Check certificate details
4. Should show "Issued by: Let's Encrypt"

## Multiple Domains

You can add multiple custom domains to the same Firebase Hosting site:

1. Follow the same process for each domain
2. All domains will serve the same app
3. Each domain gets its own SSL certificate

## Redirecting to Custom Domain

After setting up your custom domain, you may want to redirect the default Firebase URL to your custom domain:

1. Go to Firebase Console → Hosting
2. Click on your site
3. Go to **Redirects** tab
4. Add redirect from `vistarak-apps.web.app` to `yourdomain.com`

## Important Notes

- ⚠️ **DNS Propagation**: Changes can take up to 48 hours, but usually complete in 15-30 minutes
- ⚠️ **SSL Certificate**: Firebase automatically provisions SSL, but it takes 15-60 minutes
- ⚠️ **HTTPS Required**: Firebase Hosting only serves over HTTPS for custom domains
- ⚠️ **No Changes Needed in Code**: Your Flutter app code doesn't need any changes
- ✅ **Free SSL**: Firebase provides free SSL certificates via Let's Encrypt
- ✅ **Automatic Renewal**: SSL certificates are automatically renewed

## Quick Reference

| Step | Action | Time Required |
|------|--------|---------------|
| 1 | Add domain in Firebase Console | 2 minutes |
| 2 | Add DNS records to your registrar | 5 minutes |
| 3 | Wait for DNS propagation | 15-30 minutes |
| 4 | Wait for SSL certificate | 15-60 minutes |
| 5 | Test your domain | 1 minute |

**Total Time**: Approximately 30-90 minutes

## Need Help?

- Firebase Hosting Docs: https://firebase.google.com/docs/hosting/custom-domain
- Firebase Console: https://console.firebase.google.com/project/vistarak-apps/hosting
- DNS Propagation Checker: https://www.whatsmydns.net

---

**Your current Firebase URLs:**
- https://vistarak-apps.web.app
- https://vistarak-apps.firebaseapp.com

After setup, your custom domain will work alongside these URLs.

