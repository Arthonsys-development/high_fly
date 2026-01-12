#!/bin/bash

# Clean and Rebuild Flutter Project Script
# This script cleans all build artifacts and rebuilds the project

set -e

echo "🧹 Cleaning Flutter project..."

# 1. Clean Flutter build cache
flutter clean

echo "🧹 Cleaning Android build..."
# 2. Clean Android build
cd android
./gradlew clean
cd ..

echo "🧹 Cleaning iOS build..."
# 3. Clean iOS build (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd ios
    rm -rf Pods
    rm -rf Podfile.lock
    rm -rf .symlinks
    rm -rf Flutter/Flutter.framework
    rm -rf Flutter/Flutter.podspec
    pod cache clean --all || true
    cd ..
fi

echo "📦 Getting Flutter dependencies..."
# 4. Get Flutter dependencies
flutter pub get

echo "📦 Installing iOS pods (if on macOS)..."
# 5. Install iOS pods (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd ios
    pod install
    cd ..
fi

echo "✅ Clean complete!"
echo ""
echo "To rebuild:"
echo "  - Android: flutter build apk"
echo "  - iOS: flutter build ios"
echo "  - Web: flutter build web"
echo "  - Run: flutter run"

