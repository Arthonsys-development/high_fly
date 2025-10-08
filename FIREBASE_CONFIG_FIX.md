# Fix Firebase Phone Authentication Configuration Error

## Error: CONFIGURATION_NOT_FOUND

This error occurs when Firebase Phone Authentication is not properly configured. Follow these steps to fix it:

### Step 1: Enable Phone Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Phone** provider
5. Click **Enable**
6. Save the changes

### Step 2: Verify Android Configuration

1. Ensure `google-services.json` is in the correct location: `android/app/google-services.json`
2. Check that your `android/app/build.gradle` includes:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
3. Check that your `android/build.gradle` includes the Google services classpath

### Step 3: Add Required Android Configuration

Add these configurations to your Android files:

#### android/app/build.gradle
```gradle
android {
    
    defaultConfig {
        multiDexEnabled true
    }
}

dependencies {
    // ... existing dependencies ...
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.android.gms:play-services-auth'
}
```

#### android/build.gradle
```gradle
buildscript {
    dependencies {
        // ... existing dependencies ...
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Step 4: Configure Phone Authentication Settings

In Firebase Console:
1. Go to **Authentication** → **Settings** → **Authorized domains**
2. Add your domains (for testing, localhost should already be there)
3. For production, add your actual domain

### Step 5: Test Phone Numbers (Development)

For testing, you can add test phone numbers:
1. Firebase Console → **Authentication** → **Sign-in method** → **Phone**
2. Scroll down to "Phone numbers for testing"
3. Add test numbers like:
   - Phone: +1 555 123 4567
   - Code: 123456

### Step 6: Verify App Registration

1. Make sure your Android app is properly registered in Firebase Console
2. Check that the package name matches your `android/app/build.gradle` applicationId
3. Download the latest `google-services.json` if you made changes

### Step 7: Clean and Rebuild

```bash
cd "/Users/arthonsys/onGit/flutter project/Highfly"
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Common Issues and Solutions:

1. **Package Name Mismatch**: Ensure Firebase Console package name matches your app
2. **SHA Certificate**: For production, add your SHA-1 fingerprint to Firebase Console
3. **Google Play Services**: Ensure the device has Google Play Services installed
4. **Network Issues**: Check internet connectivity

### Testing with Real Numbers:

- Use your actual phone number with country code
- Format: +919887955423 (as you used)
- Ensure the number can receive SMS

If the issue persists after following these steps, the problem might be with the Firebase project configuration or regional restrictions.