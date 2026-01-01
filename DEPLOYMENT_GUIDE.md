# Web App Deployment Guide for Testing

This guide explains how to deploy your Flutter web app so testers can access it.

## Quick Start

### Option 1: Firebase Hosting (Recommended) ⭐

Firebase Hosting is already configured in your project. This is the easiest way to deploy.

**Prerequisites:**
```bash
npm install -g firebase-tools
firebase login
```

**Deploy:**
```bash
# Build the app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

**Access:**
- Production URL: `https://high-fly-21a85.web.app`
- Alternative URL: `https://high-fly-21a85.firebaseapp.com`

**Or use the automated script:**
```bash
./deploy_web.sh
```

---

### Option 2: Test Locally (Development)

For quick local testing:

```bash
# Build the app
flutter build web --release

# Serve locally
./serve_web.sh
# or
cd build/web && python3 -m http.server 8000
```

Then open: `http://localhost:8000`

**Note:** This only works on your local machine. For testers to access, use Option 1 or 3.

---

### Option 3: Netlify (Easy Drag & Drop)

1. Build the app:
   ```bash
   flutter build web --release
   ```

2. Go to [Netlify Drop](https://app.netlify.com/drop)
3. Drag and drop the `build/web` folder
4. Get instant URL (e.g., `https://random-name-123.netlify.app`)

**Pros:** Free, instant deployment, custom domains available

---

### Option 4: Vercel

1. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```

2. Build and deploy:
   ```bash
   flutter build web --release
   cd build/web
   vercel
   ```

**Pros:** Free, fast CDN, automatic HTTPS

---

### Option 5: GitHub Pages

1. Build the app:
   ```bash
   flutter build web --release --base-href "/your-repo-name/"
   ```

2. Push `build/web` contents to `gh-pages` branch

3. Enable GitHub Pages in repository settings

**URL:** `https://yourusername.github.io/your-repo-name/`

---

### Option 6: Share Build Folder (Offline Testing)

1. Build the app:
   ```bash
   flutter build web --release
   ```

2. Zip the `build/web` folder:
   ```bash
   cd build
   zip -r web-app.zip web/
   ```

3. Share the zip file with testers

4. Testers need to:
   - Extract the zip
   - Serve it using a local server (see Option 2)
   - **Cannot** just open index.html directly (CORS issues)

---

## Firebase Hosting Configuration

Your `firebase.json` is already configured:

```json
{
  "hosting": {
    "public": "build/web",
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

## Environment-Specific Builds

### Development Build
```bash
flutter build web --release --dart-define=env=dev
```

### Production Build
```bash
flutter build web --release --dart-define=env=prod
```

## Troubleshooting

### Build Fails
- Check Flutter version: `flutter --version`
- Clean build: `flutter clean && flutter pub get`
- Check for errors: `flutter analyze`

### Deployment Fails
- Ensure you're logged in: `firebase login`
- Check Firebase project: `firebase projects:list`
- Verify hosting is enabled in Firebase Console

### App Doesn't Load
- Check browser console for errors
- Ensure HTTPS is used (required for Firebase Auth)
- Verify Firebase configuration in `web/index.html`

## Best Practices

1. **Always build in release mode** for production:
   ```bash
   flutter build web --release
   ```

2. **Test locally first** before deploying

3. **Use Firebase Hosting** for easy updates and rollbacks

4. **Monitor Firebase Console** for analytics and errors

5. **Set up custom domain** in Firebase Console for production

---

## Quick Reference

| Method | Difficulty | Cost | Best For |
|--------|-----------|------|----------|
| Firebase Hosting | Easy | Free | Production & Testing |
| Netlify | Very Easy | Free | Quick Testing |
| Vercel | Easy | Free | Fast CDN |
| GitHub Pages | Medium | Free | Open Source |
| Local Server | Easy | Free | Development Only |

---

## Need Help?

- Check Firebase Console: https://console.firebase.google.com/project/high-fly-21a85
- Flutter Web Docs: https://docs.flutter.dev/deployment/web
- Firebase Hosting Docs: https://firebase.google.com/docs/hosting

