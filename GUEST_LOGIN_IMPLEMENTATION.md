# Guest Login Implementation

## Overview
Guest Login has been implemented using Firebase Anonymous Authentication, allowing users to access the app without providing phone number or email credentials.

## Implementation Details

### 1. Firebase Authentication Repository
**File:** `lib/data/repository/firebase_auth_repository.dart`

Added `signInAnonymously()` method that:
- Ensures Firebase is initialized
- Signs in the user anonymously using `FirebaseAuth.signInAnonymously()`
- Returns a `UserCredential` with the anonymous user
- Handles Firebase exceptions with appropriate error messages

### 2. Authentication Provider
**File:** `lib/module/providers/auth_provider.dart`

Added `signInAsGuest()` method that:
- Calls Firebase anonymous sign-in
- Retrieves the Firebase ID token
- Calls the backend API: `http://223.184.0.44:83/api/v1/agents/auth/verify-token/`
- Saves user data locally with `isGuest` flag set to `true`
- Registers device for notifications
- Logs analytics event for guest login
- Loads user profile (minimal for guest users)

Added `isGuestUser()` helper method to check if the current user is a guest.

### 3. Sign-In Screen UI
**File:** `lib/module/screens/authentication/signIn_screen.dart`

Added:
- **Guest Login Button**: "Continue as Guest" button with grey background
- **OR Divider**: Visual separator between phone login and guest login
- **Conditional Display**: Guest login is only shown when `organization.showSignup` is `true`
- **Loading State**: Tracks guest login loading with `_isGuestLoading` flag
- **Error Handling**: Shows appropriate error messages via SnackBar
- **Success Flow**: Navigates to dashboard after successful guest login

### 4. Secure Storage
**File:** `lib/config/constant/app_strings.dart`

Added `isGuest` key to `SharedPreferenceStrings` to track guest user status.

Updated `_secureStorageKeys` list in `AuthController` to include the `isGuest` flag.

## User Flow

### Guest Login Flow:
1. User opens the app and sees the sign-in screen
2. Guest login option is visible only if organization's `show_signup` setting is `true`
3. User clicks "Continue as Guest" button
3. App signs in anonymously via Firebase Authentication
4. App retrieves Firebase ID token
5. App calls backend API: `POST /api/v1/agents/auth/verify-token/` with:
   ```json
   {
     "id_token": "<firebase_id_token>",
     "phone_number": "9998880060"
   }
   ```
   (Note: `9998880060` is the default phone number used for all guest users)
6. App saves the response data locally with `isGuest = true`
7. App navigates to the dashboard

### Data Stored for Guest Users:
- `access_token`: Backend access token
- `id`: User ID from backend
- `full_name`: "Guest User" (default) or from backend
- `phone_number`: Phone number from backend (may be "9998880060" or empty)
- `profile_photo`: Empty string or from backend
- `isGuest`: "true" flag

### Guest User Phone Number:
All guest users send `9998880060` as the phone number in the verify-token API request. This allows the backend to:
- Identify guest user requests
- Apply appropriate permissions and limitations
- Track guest user analytics separately

### Logout:
The existing logout functionality already handles guest users properly:
- Calls logout API
- Signs out from Firebase
- Clears all secure storage (including `isGuest` flag)
- Navigates to sign-in screen

## Firebase Console Configuration

To enable Guest Login, you must enable Anonymous Authentication in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **vistarak-apps**
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Anonymous** provider
5. Click **Enable** toggle
6. Click **Save**

## Backend API Endpoint

The guest login uses the existing verify-token endpoint:
```
POST http://223.184.0.44:83/api/v1/agents/auth/verify-token/
```

**Request Body:**
```json
{
  "id_token": "firebase_anonymous_id_token",
  "phone_number": "9998880060"
}
```

**Note:** All guest users send the same phone number `9998880060` to identify them as guest users on the backend.

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "backend_access_token",
    "agent": {
      "id": "agent_id",
      "full_name": "Guest User",
      "user": {
        "phone_number": "",
        "profile_image": ""
      }
    }
  }
}
```

## Testing

### Manual Testing Steps:

**When `show_signup` is `true`:**
1. Open the app
2. On the sign-in screen, you should see:
   - Phone number input field
   - "Request OTP" button
   - "OR" divider
   - "Continue as Guest" button (grey)
   - "Need an account? Sign Up" link
3. Click "Continue as Guest"
4. The button should show loading state: "Signing in as Guest..."
5. On success, you should see a green snackbar: "Signed in as Guest"
6. The app should navigate to the dashboard

**When `show_signup` is `false`:**
1. Open the app
2. On the sign-in screen, you should see:
   - Phone number input field
   - "Request OTP" button
   - **NO** guest login option
   - **NO** sign-up link
3. Only phone OTP login is available
7. You should be able to use the app normally as a guest user

### Organization Configuration:
The guest login visibility is controlled by the organization's `show_signup` field:
- If `show_signup = true`: Guest login option is visible
- If `show_signup = false`: Guest login option is hidden

This setting is fetched from the organization API and is the same setting that controls the "Sign Up" link visibility.

### Error Scenarios:
- If Firebase anonymous auth is not enabled: Shows error message
- If backend API fails: Shows error and cleans up Firebase session
- If network is unavailable: Shows appropriate error message

## Code Locations

### Modified Files:
1. `/lib/data/repository/firebase_auth_repository.dart` - Added anonymous sign-in method
2. `/lib/module/providers/auth_provider.dart` - Added guest login controller method
3. `/lib/module/screens/authentication/signIn_screen.dart` - Added guest login UI
4. `/lib/config/constant/app_strings.dart` - Added isGuest storage key

### No New Dependencies:
All functionality uses existing Firebase Authentication package (`firebase_auth: ^6.1.4`).

## Notes

1. **Anonymous Users Can Convert**: Firebase allows converting anonymous users to regular users later if needed.
2. **Anonymous UID**: Each anonymous user gets a unique Firebase UID that persists across sessions.
3. **Data Persistence**: Guest user data is stored in secure storage and persists until logout.
4. **Backend Compatibility**: The backend should handle anonymous users properly via the verify-token endpoint.
5. **Security**: Guest users have limited access based on backend permissions.

## Troubleshooting

### If guest login fails:
1. Check Firebase Console → Authentication → Sign-in method → Anonymous is enabled
2. Verify backend API endpoint is accessible: `http://223.184.0.44:83/api/v1/agents/auth/verify-token/`
3. Check app logs for detailed error messages
4. Ensure Firebase is properly initialized in the app

### Common Issues:
- **"Operation not allowed"**: Enable Anonymous authentication in Firebase Console
- **"Token verification failed"**: Check backend API and network connectivity
- **"Firebase initialization failed"**: Verify Firebase configuration files (google-services.json, GoogleService-Info.plist)
