#!/bin/bash

# Script to get SHA-1 and SHA-256 fingerprints for Firebase
# These are needed for Firebase Authentication (Google Sign-In, Phone Auth, etc.)

echo "🔐 Getting SHA Certificate Fingerprints for Firebase"
echo "=================================================="
echo ""

# Default debug keystore location
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"
DEBUG_KEYSTORE_PASSWORD="android"
DEBUG_KEY_ALIAS="androiddebugkey"

# Check if debug keystore exists
if [ ! -f "$DEBUG_KEYSTORE" ]; then
    echo "⚠️  Debug keystore not found at: $DEBUG_KEYSTORE"
    echo "   Creating debug keystore..."
    
    # Create debug keystore if it doesn't exist
    keytool -genkey -v -keystore "$DEBUG_KEYSTORE" \
        -storepass android -alias androiddebugkey \
        -keypass android -keyalg RSA -keysize 2048 \
        -validity 10000 -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null || {
        echo "❌ Failed to create debug keystore. Please run manually:"
        echo "   keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000"
        exit 1
    }
    echo "✅ Debug keystore created"
    echo ""
fi

echo "📱 DEBUG KEYSTORE FINGERPRINTS:"
echo "--------------------------------"
echo ""

# Get SHA-1 for debug keystore
echo "SHA-1:"
DEBUG_SHA1=$(keytool -list -v -keystore "$DEBUG_KEYSTORE" -storepass "$DEBUG_KEYSTORE_PASSWORD" -alias "$DEBUG_KEY_ALIAS" 2>/dev/null | grep "SHA1:" | sed 's/.*SHA1: //' | tr -d ' ')
if [ -n "$DEBUG_SHA1" ]; then
    echo "   $DEBUG_SHA1"
else
    echo "   Error getting SHA-1"
fi

echo ""
echo "SHA-256:"
DEBUG_SHA256=$(keytool -list -v -keystore "$DEBUG_KEYSTORE" -storepass "$DEBUG_KEYSTORE_PASSWORD" -alias "$DEBUG_KEY_ALIAS" 2>/dev/null | grep "SHA256:" | sed 's/.*SHA256: //' | tr -d ' ')
if [ -n "$DEBUG_SHA256" ]; then
    echo "   $DEBUG_SHA256"
else
    echo "   Error getting SHA-256"
fi

echo ""
echo "=================================================="
echo ""

# Check for release keystore
RELEASE_KEYSTORE=""
if [ -f "android/key.properties" ]; then
    echo "📦 Checking for release keystore configuration..."
    RELEASE_KEYSTORE_PATH=$(grep "storeFile" android/key.properties | cut -d'=' -f2 | tr -d ' ' || echo "")
    
    # Convert Windows-style backslashes to forward slashes and resolve relative path
    RELEASE_KEYSTORE_PATH=$(echo "$RELEASE_KEYSTORE_PATH" | tr '\\' '/' | sed 's|//|/|g')
    
    # If path is relative, resolve it relative to android/app directory
    if [[ "$RELEASE_KEYSTORE_PATH" != /* ]]; then
        RELEASE_KEYSTORE="android/app/$RELEASE_KEYSTORE_PATH"
    else
        RELEASE_KEYSTORE="$RELEASE_KEYSTORE_PATH"
    fi
    
    # Clean up any double slashes
    RELEASE_KEYSTORE=$(echo "$RELEASE_KEYSTORE" | sed 's|//|/|g')
    
    if [ -n "$RELEASE_KEYSTORE" ] && [ -f "$RELEASE_KEYSTORE" ]; then
        echo "✅ Release keystore found: $RELEASE_KEYSTORE"
        echo ""
        echo "📱 RELEASE KEYSTORE FINGERPRINTS:"
        echo "--------------------------------"
        echo ""
        
        # Try to get release keystore info (may need password)
        STORE_PASSWORD=$(grep "storePassword" android/key.properties | cut -d'=' -f2 | tr -d ' ' || echo "")
        KEY_ALIAS=$(grep "keyAlias" android/key.properties | cut -d'=' -f2 | tr -d ' ' || echo "")
        
        if [ -n "$STORE_PASSWORD" ] && [ -n "$KEY_ALIAS" ]; then
            echo "SHA-1:"
            RELEASE_SHA1=$(keytool -list -v -keystore "$RELEASE_KEYSTORE" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" 2>/dev/null | grep "SHA1:" | sed 's/.*SHA1: //' | tr -d ' ')
            if [ -n "$RELEASE_SHA1" ]; then
                echo "   $RELEASE_SHA1"
            else
                echo "   Error getting SHA-1"
            fi
            
            echo ""
            echo "SHA-256:"
            RELEASE_SHA256=$(keytool -list -v -keystore "$RELEASE_KEYSTORE" -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" 2>/dev/null | grep "SHA256:" | sed 's/.*SHA256: //' | tr -d ' ')
            if [ -n "$RELEASE_SHA256" ]; then
                echo "   $RELEASE_SHA256"
            else
                echo "   Error getting SHA-256"
            fi
        else
            echo "⚠️  Release keystore password/alias not found in key.properties"
            echo "   To get release fingerprints, run manually:"
            echo "   keytool -list -v -keystore <your-release-keystore> -alias <your-alias>"
        fi
    else
        echo "⚠️  Release keystore not found at: $RELEASE_KEYSTORE"
        echo "   Expected path: $RELEASE_KEYSTORE"
    fi
else
    echo "ℹ️  No release keystore configuration found (android/key.properties)"
fi

echo ""
echo "=================================================="
echo ""
echo "📋 HOW TO ADD TO FIREBASE:"
echo "1. Go to Firebase Console: https://console.firebase.google.com/"
echo "2. Select your project: vistarak-apps"
echo "3. Go to Project Settings (gear icon)"
echo "4. Scroll to 'Your apps' section"
echo "5. Click on your Android app (vistarak.apps)"
echo "6. Click 'Add fingerprint'"
echo "7. Paste the SHA-1 and SHA-256 values above"
echo ""
echo "💡 Note: You need to add BOTH debug and release fingerprints"
echo "   if you plan to use Firebase Auth in both debug and release builds"

