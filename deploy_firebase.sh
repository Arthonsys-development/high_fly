#!/bin/bash

# Firebase Hosting Deployment Script
# This script builds and deploys the Flutter web app to Firebase Hosting

set -e  # Exit on error

echo "🔥 Firebase Hosting Deployment"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Find Flutter
FLUTTER_CMD=""
if command -v flutter &> /dev/null; then
  FLUTTER_CMD="flutter"
elif [ -n "$FLUTTER_ROOT" ]; then
  FLUTTER_CMD="$FLUTTER_ROOT/bin/flutter"
else
  FLUTTER_PATHS=(
    "$HOME/flutter/bin/flutter"
    "/usr/local/bin/flutter"
    "/opt/homebrew/bin/flutter"
  )
  for path in "${FLUTTER_PATHS[@]}"; do
    if [ -f "$path" ]; then
      FLUTTER_CMD="$path"
      break
    fi
  done
fi

if [ -z "$FLUTTER_CMD" ]; then
  echo -e "${RED}❌ Flutter not found!${NC}"
  echo "Please install Flutter or add it to your PATH"
  exit 1
fi

echo -e "${GREEN}✅ Found Flutter${NC}"
echo ""

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
  echo -e "${YELLOW}⚠️  Firebase CLI not found!${NC}"
  echo ""
  echo "Installing Firebase CLI..."
  if command -v npm &> /dev/null; then
    npm install -g firebase-tools
  else
    echo -e "${RED}❌ npm not found. Please install Node.js and npm first.${NC}"
    echo "Then run: npm install -g firebase-tools"
    exit 1
  fi
fi

echo -e "${GREEN}✅ Firebase CLI found${NC}"
echo ""

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
  echo -e "${YELLOW}⚠️  Not logged in to Firebase${NC}"
  echo "Logging in to Firebase..."
  firebase login
fi

echo -e "${GREEN}✅ Firebase authentication verified${NC}"
echo ""

# Get project directory
cd "$(dirname "$0")"

# Step 1: Get dependencies
echo -e "${BLUE}📦 Step 1: Getting dependencies...${NC}"
$FLUTTER_CMD pub get

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Failed to get dependencies${NC}"
  exit 1
fi

echo ""

# Step 2: Clean previous build
echo -e "${BLUE}🧹 Step 2: Cleaning previous build...${NC}"
$FLUTTER_CMD clean

echo ""

# Step 3: Build web app
echo -e "${BLUE}🔨 Step 3: Building web app (release mode - production)...${NC}"
$FLUTTER_CMD build web --release --dart-define=env=prod

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Build failed${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""

# Step 4: Deploy to Firebase
echo -e "${BLUE}🚀 Step 4: Deploying to Firebase Hosting...${NC}"
echo ""

firebase deploy --only hosting

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo -e "${GREEN}✅ Deployment successful!${NC}"
  echo -e "${GREEN}════════════════════════════════════════${NC}"
  echo ""
  echo -e "${BLUE}🌐 Your app is live at:${NC}"
  echo -e "   ${YELLOW}https://vistarak-apps.web.app${NC}"
  echo -e "   ${YELLOW}https://vistarak-apps.firebaseapp.com${NC}"
  echo ""
  echo -e "${BLUE}📊 View hosting dashboard:${NC}"
  echo -e "   ${YELLOW}https://console.firebase.google.com/project/vistarak-apps/hosting${NC}"
  echo ""
else
  echo ""
  echo -e "${RED}❌ Deployment failed${NC}"
  echo "Check the error messages above for details"
  exit 1
fi

