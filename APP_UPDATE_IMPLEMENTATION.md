# App Update Implementation Guide

## Overview
This implementation adds automatic app update checking functionality to the HighFly app. The app now checks for updates when it starts and displays appropriate dialogs based on whether the update is mandatory or optional.

## Changes Made

### 1. Data Models Updated
**File:** `lib/data/models/response_model/organization_response_model.dart`

Added three new model classes to handle the app update data from the API:

- **`AppVersionInfo`**: Represents version information for a specific platform
  - `version`: The version string (e.g., "1.0.7")
  - `isMandatoryUpdate`: Whether the update is mandatory
  - `message`: Custom message to display to users

- **`AppUpdate`**: Contains version info for both platforms
  - `ios`: iOS version information
  - `android`: Android version information

- **`Organization`**: Updated to include:
  - `appUpdate`: The new app update field

### 2. New Service Created
**File:** `lib/utils/app_update_service.dart`

Created a comprehensive service to handle all app update functionality:

#### Key Features:
- **Version Comparison**: Smart semantic version comparison (major.minor.patch)
- **Platform Detection**: Automatically detects iOS, Android, or Web
- **Update Dialog**: Beautiful, user-friendly update dialogs with:
  - Different styling for mandatory vs optional updates
  - Warning indicators for mandatory updates
  - Non-dismissible dialog for mandatory updates
- **App Store Integration**: Opens the appropriate app store for updates

#### Main Methods:
```dart
// Check if update is available
static Future<(bool, bool, String?)> checkForUpdate(Organization? organization)

// Show update dialog to user
static Future<bool> showUpdateDialog({
  required BuildContext context,
  required bool isMandatory,
  String? message,
})

// Open app store for update
static Future<void> openAppStore()
```

### 3. Splash Screen Integration
**File:** `lib/module/screens/onboarding/splash_screen.dart`

Updated the splash screen to check for app updates:

- Checks for updates after loading organization data
- Shows update dialog if an update is available
- For mandatory updates:
  - Prevents app navigation until update is completed
  - Shows persistent messages to update
  - Keeps user on splash screen
- For optional updates:
  - Allows user to skip and continue to app
  - Opens app store if user chooses to update

### 4. Dependencies Added
**File:** `pubspec.yaml`

Added `package_info_plus: ^8.1.2` for retrieving current app version information.

## API Response Structure

The organization API now returns this structure:

```json
{
  "success": true,
  "organization": {
    "id": "5b7bf2e2-2f47-4bf7-9032-fa8f2c2b9417",
    "name": "Vistarak",
    "app_update": {
      "ios": {
        "version": "1.0.7",
        "is_mandatory_update": true,
        "message": "Update app"
      },
      "android": {
        "version": "1.0.7",
        "is_mandatory_update": true,
        "message": "Update app"
      }
    }
  }
}
```

## How It Works

1. **App Starts**: User opens the app
2. **Organization Load**: Splash screen loads organization data from API
3. **Version Check**: Compares current app version with API version
4. **Update Dialog**: If update available, shows appropriate dialog
5. **User Action**:
   - **Mandatory Update**: User must update to continue
   - **Optional Update**: User can choose to update or skip
6. **App Store**: If user chooses to update, opens app store

## Version Comparison Logic

The service uses semantic versioning comparison:
- Compares major.minor.patch independently
- Example: 1.0.1 < 1.0.7 (update available)
- Example: 1.1.0 > 1.0.7 (no update needed)

## User Experience

### Mandatory Update Dialog:
- 🟠 Orange warning icon
- "Update Required" title
- Non-dismissible (user cannot close it)
- Warning banner explaining mandatory nature
- "Update Now" button (orange)

### Optional Update Dialog:
- 🔵 Blue info icon
- "Update Available" title
- Dismissible (user can close it)
- Custom message from API
- "Later" and "Update Now" buttons

## Configuration

### App Store URLs
Update these URLs in `lib/utils/app_update_service.dart`:

```dart
// iOS App Store URL
url = 'https://apps.apple.com/app/your-app-id';

// Android Play Store URL
url = 'https://play.google.com/store/apps/details?id=com.vistarak.highfly';
```

## Testing

To test the update functionality:

1. **Set lower version in pubspec.yaml:**
   ```yaml
   version: 1.0.1+5
   ```

2. **Ensure API returns higher version:**
   ```json
   {
     "version": "1.0.7",
     "is_mandatory_update": true,
     "message": "Update app"
   }
   ```

3. **Run the app** and observe the update dialog

## Installation

Run the following command to install the new dependency:

```bash
flutter pub get
```

## Debug Logging

The service provides detailed debug logs:
- Current app version
- Available version from API
- Whether update is available
- Whether update is mandatory
- Update message

Example log output:
```
🔄 App Update Check:
  Current Version: 1.0.1
  Available Version: 1.0.7
  Update Available: true
  Mandatory: true
  Message: Update app
```

## Future Enhancements

Possible future improvements:
1. In-app update for Android (using in_app_update package)
2. Auto-download for optional updates
3. Update scheduling (remind later)
4. Update history tracking
5. Release notes display
6. Progressive update rollout support

## Notes

- **Web Platform**: Updates are handled automatically by reloading the page
- **iOS Platform**: Uses App Store links for updates
- **Android Platform**: Uses Play Store links for updates
- **Version Format**: Must follow semantic versioning (major.minor.patch)
