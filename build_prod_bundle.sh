#!/bin/bash

# Build Production App Bundle for Google Play
# This script builds a release App Bundle (AAB) with production environment configuration

set -e

echo "🏗️  Building Production App Bundle for Google Play..."
echo ""

# Try to source shell configs to get Flutter in PATH
if [ -f ~/.zshrc ]; then
    source ~/.zshrc >/dev/null 2>&1
elif [ -f ~/.bash_profile ]; then
    source ~/.bash_profile >/dev/null 2>&1
fi

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter command not found!"
    echo ""
    echo "Please ensure Flutter is installed and in your PATH."
    echo "You can:"
    echo "  1. Add Flutter to your PATH in ~/.zshrc or ~/.bash_profile"
    echo "  2. Run this script from a terminal where Flutter is configured"
    echo "  3. Or specify Flutter path manually in this script"
    echo ""
    exit 1
fi

# Verify .env.prod exists
if [ ! -f "assets/env/.env.prod" ]; then
    echo "⚠️  Warning: assets/env/.env.prod not found!"
    echo "   The app will use fallback production values."
    echo ""
fi

# Build the App Bundle with production environment
echo "📱 Building release App Bundle with env=prod..."
flutter build appbundle --release --dart-define=env=prod

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 App Bundle Location:"
echo "   build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "📊 App Bundle Size:"
ls -lh build/app/outputs/bundle/release/app-release.aab | awk '{print $5}'
echo ""
echo "📤 You can now upload this AAB to Google Play Console!"
echo ""
echo "💡 To upload to Google Play:"
echo "   1. Go to Google Play Console"
echo "   2. Select your app"
echo "   3. Go to Production > Create new release"
echo "   4. Upload: build/app/outputs/bundle/release/app-release.aab"
echo ""
