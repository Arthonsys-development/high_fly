# Firebase Hosting Deployment Guide

This guide will help you deploy your Flutter web app to Firebase Hosting.

## 🚀 Quick Start

### One-Command Deployment

The easiest way to deploy is using the automated script:

```bash
./deploy_firebase.sh
```

This script will:
1. ✅ Check for Flutter and Firebase CLI
2. ✅ Get project dependencies
3. ✅ Clean previous builds
4. ✅ Build the web app in release mode
5. ✅ Deploy to Firebase Hosting

### Manual Deployment

If you prefer to deploy manually:

```bash
# 1. Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Build the web app
flutter build web --release

# 4. Deploy to Firebase
firebase deploy --only hosting
```

## 📋 Prerequisites

1. **Flutter SDK** - Installed and in your PATH
2. **Node.js and npm** - For Firebase CLI
3. **Firebase Account** - With a project created
4. **Firebase CLI** - Installed globally

### Installing Firebase CLI

```bash
npm install -g firebase-tools
```

### Login to Firebase

```bash
firebase login
```

This will open a browser window for authentication.

## 🔧 Configuration

### Firebase Project

Your project is configured to use: **vistarak-apps**

This is set in `.firebaserc`:
```json
{
  "projects": {
    "default": "vistarak-apps"
  }
}
```

### Hosting Configuration

The `firebase.json` file is configured with:
- **Public directory**: `build/web` (Flutter web build output)
- **Rewrites**: All routes redirect to `index.html` (for Flutter routing)
- **Caching headers**: Optimized for performance
- **Security headers**: XSS protection, frame options, etc.

## 🌐 Access Your Deployed App

After deployment, your app will be available at:

- **Primary URL**: https://vistarak-apps.web.app
- **Alternative URL**: https://vistarak-apps.firebaseapp.com

### View Hosting Dashboard

Monitor your deployment at:
https://console.firebase.google.com/project/vistarak-apps/hosting

## 📝 Deployment Steps Explained

### 1. Build the Web App

```bash
flutter build web --release
```

This creates an optimized production build in `build/web/`.

**Build Options:**
- `--release`: Production build (optimized, minified)
- `--dart-define=env=prod`: Use production environment variables
- `--base-href=/`: Set base path (default is `/`)

### 2. Deploy to Firebase

```bash
firebase deploy --only hosting
```

**Deploy Options:**
- `--only hosting`: Deploy only hosting (faster)
- `--project vistarak-apps`: Specify project (if not default)
- `--message "Deploy message"`: Add deployment message

## 🔄 Updating Your App

To update your deployed app:

```bash
# Option 1: Use the automated script
./deploy_firebase.sh

# Option 2: Manual update
flutter build web --release
firebase deploy --only hosting
```

## 🎯 Environment-Specific Builds

### Development Build

```bash
flutter build web --release --dart-define=env=dev
firebase deploy --only hosting
```

### Production Build

```bash
flutter build web --release --dart-define=env=prod
firebase deploy --only hosting
```

## 🔍 Troubleshooting

### Build Fails

**Problem**: Flutter build fails

**Solutions**:
- Check Flutter version: `flutter --version`
- Clean build: `flutter clean && flutter pub get`
- Check for errors: `flutter analyze`
- Ensure all dependencies are installed: `flutter pub get`

### Deployment Fails

**Problem**: Firebase deployment fails

**Solutions**:
- Verify login: `firebase login`
- Check project: `firebase projects:list`
- Verify hosting is enabled in Firebase Console
- Check `firebase.json` syntax
- Ensure `build/web` directory exists

### App Doesn't Load

**Problem**: App shows blank page or errors

**Solutions**:
- Check browser console for errors
- Verify Firebase configuration in `web/index.html`
- Ensure HTTPS is used (required for Firebase Auth)
- Check network tab for failed resource loads
- Verify all assets are included in build

### Firebase CLI Not Found

**Problem**: `firebase: command not found`

**Solutions**:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version

# If npm is not found, install Node.js first
# macOS: brew install node
# Linux: Use package manager
# Windows: Download from nodejs.org
```

### Authentication Issues

**Problem**: `firebase login` fails

**Solutions**:
- Clear Firebase cache: `firebase logout` then `firebase login`
- Use token: `firebase login --no-localhost`
- Check internet connection
- Verify Firebase account access

## 📊 Monitoring & Analytics

### View Deployment History

```bash
firebase hosting:channel:list
```

### View Site Analytics

Visit Firebase Console:
https://console.firebase.google.com/project/vistarak-apps/hosting

### Check Deployment Status

```bash
firebase hosting:channel:list
```

## 🔐 Custom Domain Setup

To use a custom domain:

1. Go to Firebase Console → Hosting
2. Click "Add custom domain"
3. Follow the verification steps
4. Update DNS records as instructed

## 🚀 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Firebase

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: vistarak-apps
```

## 📚 Additional Resources

- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Firebase Console](https://console.firebase.google.com/project/vistarak-apps)

## ✅ Checklist

Before deploying, ensure:

- [ ] Flutter SDK is installed and up to date
- [ ] Firebase CLI is installed (`firebase --version`)
- [ ] Logged in to Firebase (`firebase login`)
- [ ] Project dependencies are installed (`flutter pub get`)
- [ ] Environment files are configured
- [ ] Firebase configuration in `web/index.html` is correct
- [ ] Build succeeds locally (`flutter build web --release`)
- [ ] Tested locally (`flutter run -d chrome`)

## 🎉 Success!

Once deployed, your app will be:
- ✅ Live on Firebase Hosting
- ✅ Served over HTTPS
- ✅ CDN-accelerated globally
- ✅ Automatically cached for performance
- ✅ Protected with security headers

---

**Need Help?** Check the [Firebase Console](https://console.firebase.google.com/project/vistarak-apps) or review the troubleshooting section above.

