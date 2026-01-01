#!/bin/bash

# Flutter Web Build Script
# This script builds the Flutter web app

echo "🔍 Searching for Flutter installation..."

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
    if [ -f "$path" ]; then
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
  echo "   /path/to/flutter/bin/flutter build web"
  echo ""
  echo "3. Or install Flutter via Homebrew:"
  echo "   brew install --cask flutter"
  exit 1
fi

echo ""
echo "📦 Getting project dependencies..."
cd "$(dirname "$0")"
$FLUTTER_CMD pub get

echo ""
echo "🌐 Building web app..."
$FLUTTER_CMD build web --release

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Web build complete!"
  echo "📁 Build output is in: build/web/"
  echo ""
  echo "To serve the build locally, run:"
  echo "  cd build/web && python3 -m http.server 8000"
  echo "  Then open http://localhost:8000 in your browser"
else
  echo ""
  echo "❌ Build failed!"
  exit 1
fi

