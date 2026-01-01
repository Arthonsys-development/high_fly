#!/bin/bash

# Flutter Web Deployment Script
# This script builds and deploys the web app for testing

echo "🚀 Flutter Web Deployment Script"
echo "================================"
echo ""

# Try to find Flutter
FLUTTER_PATHS=(
  "$HOME/flutter/bin/flutter"
  "/usr/local/bin/flutter"
  "/opt/homebrew/bin/flutter"
)

FLUTTER_CMD=""

if command -v flutter &> /dev/null; then
  FLUTTER_CMD="flutter"
  echo "✅ Found Flutter in PATH"
elif [ -n "$FLUTTER_ROOT" ]; then
  FLUTTER_CMD="$FLUTTER_ROOT/bin/flutter"
  echo "✅ Found Flutter via FLUTTER_ROOT: $FLUTTER_ROOT"
else
  for path in "${FLUTTER_PATHS[@]}"; do
    if [ -f "$path" ]; then
      FLUTTER_CMD="$path"
      echo "✅ Found Flutter at: $path"
      break
    fi
  done
fi

if [ -z "$FLUTTER_CMD" ]; then
  echo "❌ Flutter not found!"
  echo "Please ensure Flutter is installed and in your PATH"
  exit 1
fi

cd "$(dirname "$0")"

echo ""
echo "📦 Step 1: Getting dependencies..."
$FLUTTER_CMD pub get

if [ $? -ne 0 ]; then
  echo "❌ Failed to get dependencies"
  exit 1
fi

echo ""
echo "🔨 Step 2: Building web app (release mode)..."
$FLUTTER_CMD build web --release

if [ $? -ne 0 ]; then
  echo "❌ Build failed"
  exit 1
fi

echo ""
echo "✅ Build complete! Web app is ready in: build/web/"
echo ""
echo "📋 Deployment Options:"
echo ""
echo "1️⃣  Firebase Hosting (Recommended - Already configured)"
echo "   Run: firebase deploy --only hosting"
echo "   URL: https://high-fly-21a85.web.app"
echo ""
echo "2️⃣  Test Locally"
echo "   Run: ./serve_web.sh"
echo "   Then open: http://localhost:8000"
echo ""
echo "3️⃣  Share build folder"
echo "   Zip the build/web folder and share with testers"
echo ""
echo "4️⃣  Other hosting services"
echo "   - Netlify: Drag & drop build/web folder"
echo "   - Vercel: vercel deploy build/web"
echo "   - GitHub Pages: See DEPLOYMENT_GUIDE.md"
echo ""

# Check if Firebase CLI is available
if command -v firebase &> /dev/null; then
  echo "🔥 Firebase CLI detected!"
  echo ""
  read -p "Do you want to deploy to Firebase Hosting now? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Deploying to Firebase Hosting..."
    firebase deploy --only hosting
    
    if [ $? -eq 0 ]; then
      echo ""
      echo "✅ Deployment successful!"
      echo "🌐 Your app is live at: https://high-fly-21a85.web.app"
      echo "   (or https://high-fly-21a85.firebaseapp.com)"
    else
      echo ""
      echo "❌ Deployment failed. Check the error messages above."
    fi
  fi
else
  echo "💡 Tip: Install Firebase CLI to deploy easily:"
  echo "   npm install -g firebase-tools"
  echo "   firebase login"
  echo "   firebase deploy --only hosting"
fi

echo ""
echo "✨ Done!"

