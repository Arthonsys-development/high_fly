#!/bin/bash

# Firebase iOS Fix Script
# This script helps fix common Firebase iOS configuration issues

echo "🔧 Firebase iOS Fix Script"
echo "=========================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the root of your Flutter project"
    exit 1
fi

echo "✅ Found Flutter project"

# Clean Flutter
echo "🧹 Cleaning Flutter project..."
flutter clean
flutter pub get

# Navigate to iOS directory
echo "📱 Updating iOS dependencies..."
cd ios

# Check if Podfile exists
if [ ! -f "Podfile" ]; then
    echo "❌ Error: Podfile not found in iOS directory"
    cd ..
    exit 1
fi

# Update pods
echo "🔄 Updating CocoaPods repositories..."
pod repo update

echo "📦 Installing pods..."
pod install

# Check if pod install succeeded
if [ $? -ne 0 ]; then
    echo "❌ Error: pod install failed"
    cd ..
    exit 1
fi

# Go back to project root
cd ..

echo "✅ iOS Firebase setup completed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Check that GoogleService-Info.plist is properly configured"
echo "3. Ensure Firebase is initialized in AppDelegate.swift"
echo "4. Run the app on an iOS device to test phone authentication"
echo ""
echo "💡 If you still encounter issues:"
echo "- Verify your Firebase project settings"
echo "- Check that phone authentication is enabled in Firebase Console"
echo "- Ensure your bundle ID matches the one in Firebase Console"