#!/bin/bash

# Build Production APK for Testers
# This script builds a release APK with production environment configuration

set -e

echo "🏗️  Building Production APK for Testers..."
echo ""

# Build the APK with production environment
echo "📱 Building release APK with env=prod..."
flutter build apk --release --dart-define=env=prod

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 APK Location:"
echo "   build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "📊 APK Size:"
ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}'
echo ""
echo "📤 You can now share this APK with testers!"
echo ""
echo "💡 To install on a device:"
echo "   adb install build/app/outputs/flutter-apk/app-release.apk"


