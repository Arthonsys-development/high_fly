#!/bin/bash

# Build Production iOS App
# This script builds a release iOS app with production environment configuration

set -e

echo "🏗️  Building Production iOS App..."
echo ""

# Try to find Flutter in common locations
FLUTTER_PATHS=(
  "$HOME/flutter/bin/flutter"
  "/usr/local/bin/flutter"
  "/opt/homebrew/bin/flutter"
  "$HOME/.pub-cache/hosted/pub.dev/flutter_tools-*/bin/flutter"
)

FLUTTER_CMD=""

# Check if flutter is in PATH
if command -v flutter &> /dev/null; then
  FLUTTER_CMD="flutter"
  echo "✅ Found Flutter in PATH"
elif [ -n "$FLUTTER_ROOT" ]; then
  FLUTTER_CMD="$FLUTTER_ROOT/bin/flutter"
  echo "✅ Found Flutter via FLUTTER_ROOT: $FLUTTER_ROOT"
else
  # Try to find in common locations
  for path in "${FLUTTER_PATHS[@]}"; do
    # Handle glob patterns
    if [[ "$path" == *"*"* ]]; then
      found=$(find "$HOME/.pub-cache" -name "flutter" -type f 2>/dev/null | grep "flutter_tools" | head -1)
      if [ -n "$found" ]; then
        FLUTTER_CMD="$found"
        echo "✅ Found Flutter at: $found"
        break
      fi
    elif [ -f "$path" ]; then
      FLUTTER_CMD="$path"
      echo "✅ Found Flutter at: $path"
      break
    fi
  done
fi

if [ -z "$FLUTTER_CMD" ]; then
  echo "❌ Flutter not found!"
  echo ""
  echo "Please do one of the following:"
  echo "1. Add Flutter to your PATH in ~/.zshrc:"
  echo "   export PATH=\"\$PATH:/path/to/flutter/bin\""
  echo ""
  echo "2. Or run Flutter directly:"
  echo "   /path/to/flutter/bin/flutter build ios --release --dart-define=env=prod"
  echo ""
  echo "3. Or install Flutter via Homebrew:"
  echo "   brew install --cask flutter"
  exit 1
fi

echo ""
echo "📱 Building iOS release with env=prod..."
$FLUTTER_CMD build ios --release --dart-define=env=prod

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 Build Location:"
echo "   build/ios/iphoneos/Runner.app"
echo ""
echo "💡 To create an IPA file for distribution:"
echo "   $FLUTTER_CMD build ipa --dart-define=env=prod"
echo ""
