#!/bin/bash

# Simple HTTP Server Script for Flutter Web Build
# This script serves the built web app on a local HTTP server

BUILD_DIR="build/web"
PORT=8000

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
  echo "❌ Build directory not found: $BUILD_DIR"
  echo "Please run 'flutter build web --release' first"
  exit 1
fi

echo "🌐 Starting local web server..."
echo "📁 Serving from: $(pwd)/$BUILD_DIR"
echo "🔗 Open your browser and navigate to:"
echo ""
echo "   http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Try different methods to start a server
cd "$BUILD_DIR"

# Try Python 3 first (most common)
if command -v python3 &> /dev/null; then
  echo "✅ Using Python 3 HTTP server"
  python3 -m http.server $PORT
# Try Python 2
elif command -v python &> /dev/null; then
  echo "✅ Using Python HTTP server"
  python -m SimpleHTTPServer $PORT
# Try PHP
elif command -v php &> /dev/null; then
  echo "✅ Using PHP built-in server"
  php -S localhost:$PORT
# Try Node.js http-server
elif command -v npx &> /dev/null; then
  echo "✅ Using Node.js http-server"
  npx http-server -p $PORT
else
  echo "❌ No suitable HTTP server found!"
  echo ""
  echo "Please install one of the following:"
  echo "  - Python 3: brew install python3"
  echo "  - PHP: brew install php"
  echo "  - Node.js: brew install node"
  exit 1
fi

