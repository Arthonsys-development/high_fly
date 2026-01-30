# Version-Based Signup Control

## Overview
The SignIn screen now includes intelligent signup visibility control based on app version comparison. This allows you to control whether users can sign up based on their current app version compared to the version specified in the API.

## How It Works

### Logic Flow:
1. **API Flag Check**: First checks if `showSignup` is `true` in the API
   - If `false`, signup UI is hidden regardless of version
   
2. **Version Comparison**: If API flag is `true`, compares versions:
   - Current app version (from `package_info_plus`)
   - API version (from organization `app_update` field)
   
3. **Result**: Shows signup UI only if:
   - `showSignup` API flag is `true` AND
   - Current app version > API version

## Version Conversion

Versions are converted to numbers for easy comparison:

```
Version String → Number
1.0.3 → 103
1.0.7 → 107
2.1.5 → 215
```

Formula: `(major × 100) + (minor × 10) + patch`

## Example Scenarios

### Scenario 1: Hide Signup (Version Too Old)
```
Current Version: 1.0.1 → 101
API Version: 1.0.7 → 107
showSignup: true

Result: 101 > 107 = false → Signup HIDDEN
```

### Scenario 2: Show Signup (Version Newer)
```
Current Version: 1.0.8 → 108
API Version: 1.0.7 → 107
showSignup: true

Result: 108 > 107 = true → Signup SHOWN
```

### Scenario 3: API Flag Overrides
```
Current Version: 1.0.8 → 108
API Version: 1.0.7 → 107
showSignup: false

Result: API flag is false → Signup HIDDEN (regardless of version)
```

## Implementation Details

### Added to signIn_screen.dart:

1. **Import Statements:**
   ```dart
   import 'package:package_info_plus/package_info_plus.dart';
   import 'dart:io';
   import 'package:flutter/foundation.dart' show kIsWeb;
   import '../../../data/models/response_model/organization_response_model.dart';
   ```

2. **State Variable:**
   ```dart
   String? _currentAppVersion; // Store current app version
   ```

3. **New Methods:**
   - `_getCurrentAppVersion()`: Fetches current app version
   - `_versionToNumber(String)`: Converts version string to number
   - `_shouldShowSignup(Organization?)`: Determines signup visibility

### Method: `_shouldShowSignup()`

```dart
bool _shouldShowSignup(Organization? organization) {
  // Check API flag first
  final apiShowSignup = organization?.showSignup ?? false;
  if (!apiShowSignup) return false;
  
  // Version comparison logic
  // Returns true if current version > API version
}
```

## Debug Logging

The implementation includes detailed debug logs:

```
📱 Signup Visibility Check:
  API showSignup flag: true
  Current Version: 1.0.1 (101)
  API Version: 1.0.7 (107)
  Current > API: false
```

## Platform Handling

- **Web**: Always shows signup if API flag is true (no version check)
- **iOS**: Compares with `app_update.ios.version`
- **Android**: Compares with `app_update.android.version`

## Use Cases

### Use Case 1: Force Users to Update
Set API version higher than most users' versions:
- Users with old versions see "Update Required" dialog
- Signup is hidden for old versions
- Only updated users can create new accounts

### Use Case 2: Beta Testing
During beta testing with version 2.0.0:
- Set API version to 1.9.9
- Beta testers (v2.0.0+) can sign up
- Production users (v1.x.x) cannot sign up

### Use Case 3: Gradual Rollout
Control new user onboarding during staged rollouts:
- Initial release: High API version (signup hidden)
- After stability confirmed: Lower API version (signup shown)

## API Response Example

```json
{
  "success": true,
  "organization": {
    "name": "Vistarak",
    "show_signup": true,
    "app_update": {
      "ios": {
        "version": "1.0.7"
      },
      "android": {
        "version": "1.0.7"
      }
    }
  }
}
```

## Testing

### Test Case 1: Old Version (Signup Hidden)
1. Set `pubspec.yaml` version to `1.0.1+5`
2. Set API version to `1.0.7`
3. Set `show_signup: true`
4. Expected: Signup UI is hidden

### Test Case 2: New Version (Signup Shown)
1. Set `pubspec.yaml` version to `1.0.8+8`
2. Set API version to `1.0.7`
3. Set `show_signup: true`
4. Expected: Signup UI is shown

### Test Case 3: API Flag Override
1. Any version in `pubspec.yaml`
2. Any API version
3. Set `show_signup: false`
4. Expected: Signup UI is hidden

## UI Elements Controlled

When signup is hidden, these elements are not shown:
- Guest login button
- "OR" divider
- "Need an account? Sign Up" link

When signup is shown, all these elements appear after the phone input field.

## Configuration

No additional configuration needed. The feature automatically uses:
- Current app version from `package_info_plus`
- API version from organization endpoint
- `show_signup` flag from organization endpoint

## Benefits

1. **Version Control**: Ensure only updated users can sign up
2. **Security**: Prevent old, potentially vulnerable versions from creating accounts
3. **Quality Control**: Ensure new users have the best experience
4. **Flexibility**: Backend-controlled without app updates
5. **Gradual Rollout**: Control feature availability per version

## Notes

- Version comparison is case-insensitive
- Handles missing versions gracefully (defaults to showing signup)
- Web platform always shows signup if API flag is true
- Debug logs help troubleshoot visibility issues
- No breaking changes to existing functionality
