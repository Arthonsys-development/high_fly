# Firebase Web Phone Authentication Setup

## Current Implementation Status

✅ **Mobile Platform**: Fully implemented and working
✅ **Firebase Web Config**: ✅ **CONFIGURED** for project: `high-fly-21a85`
⚠️ **Web Phone Auth**: Structure ready, requires Firebase Console setup

## ✅ Configuration Completed

Your Firebase web configuration has been successfully updated with:
- **Project ID**: high-fly-21a85
- **Auth Domain**: high-fly-21a85.firebaseapp.com
- **API Key**: Configured
- **App ID**: Configured

## Next Steps to Enable Web Phone Authentication

### Step 1: Enable Phone Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/high-fly-21a85/authentication/providers)
2. Click on **Authentication** → **Sign-in method**
3. Find **Phone** provider and click **Enable**
4. Click **Save**

### Step 2: Add Authorized Domains

1. In Firebase Console, go to **Authentication** → **Settings** → **Authorized domains**
2. Add these domains:
   - `localhost` (for development)
   - Your production domain (when deploying)

### Step 3: Test Phone Authentication

1. Run the web app:
   ```bash
   flutter run -d chrome
   ```

2. Navigate to the sign-in screen
3. Enter a phone number
4. The reCAPTCHA should appear
5. Complete verification

## Step 4: Configure Phone Authentication for Web

### Important Web-Specific Requirements:

1. **Domain Authorization**: 
   - Add your domain (localhost for development) to Firebase Console
   - Go to Authentication → Settings → Authorized domains

2. **reCAPTCHA**: 
   - Web platform requires reCAPTCHA verification
   - The `recaptcha-container` div is already added to index.html

3. **HTTPS Requirement**:
   - Production domains must use HTTPS
   - localhost works for development

## Step 5: Test the Implementation

1. Run the web app: `flutter run -d chrome`
2. Navigate to the sign-in screen
3. Enter a phone number and test the flow
4. The reCAPTCHA will appear for verification

## Troubleshooting

### Common Issues:

1. **reCAPTCHA not showing**: Check if domain is authorized in Firebase Console
2. **Configuration errors**: Verify Firebase config values in index.html
3. **CORS errors**: Ensure your domain is in authorized domains list
4. **Phone auth not working**: Verify billing is enabled in Firebase Console

### Testing Phone Numbers:

For development, you can add test phone numbers in Firebase Console:
- Go to Authentication → Sign-in method → Phone
- Scroll to "Phone numbers for testing"
- Add test numbers with fixed verification codes

Example:
- Phone: `+1 650-555-3434`
- Code: `123456`

## Security Notes

1. Never expose Firebase config in production without proper domain restrictions
2. Configure authorized domains properly for production
3. Monitor usage in Firebase Console to avoid unexpected charges
4. Use test phone numbers during development to avoid SMS charges