# Notification Permissions Implementation

## Overview

This document describes the notification permissions implementation in the HighFly application. The implementation includes:

1. Requesting notification permissions from users
2. Checking current permission status
3. Handling permission denial and permanently denied states
4. Integrating with FCM token registration
5. Supporting both mobile platforms (Android and iOS)

## Implementation Details

### Dependencies

The implementation uses the following packages:
- `permission_handler`: For requesting and checking notification permissions
- `firebase_messaging`: For FCM token management
- `flutter_riverpod`: For state management

### Code Structure

#### 1. FCM Provider (`lib/module/providers/fcm_provider.dart`)

The FCM provider handles notification permissions and FCM token management:

##### Methods
- `requestNotificationPermission()`: Requests notification permission from the user
- `checkNotificationPermission()`: Checks the current permission status
- `getFcmToken()`: Gets FCM token only if permission is granted

#### 2. Notification Permission Widget (`lib/module/widgets/notification_permission_widget.dart`)

A reusable widget that provides a UI for:
- Displaying current permission status
- Requesting permissions
- Checking permissions
- Showing FCM token information
- Displaying errors

#### 3. Notification Permission Screen (`lib/module/screens/notification_permission_screen.dart`)

A complete screen demonstrating the notification permission functionality with:
- Permission management UI
- Information about notifications
- Explanation of how the system works

## Key Features

### Platform-Specific Handling

#### Android
- Requests notification permissions like other apps
- Follows standard Android notification permission model

#### iOS
- Requests notification permissions as required by the platform
- Uses standard iOS notification permission dialogs
- Requests specific permission types (alert, badge, sound)

#### Web
- Notification permissions are not fully supported in this implementation
- Returns appropriate error messages

### Permission Request Flow

1. Request notification permission from user
2. If granted, get FCM token
3. Register token with backend server
4. Listen for token refreshes

### Error Handling

The implementation includes comprehensive error handling for:
- Permission request failures
- FCM token retrieval errors
- Network issues during token registration
- Permission permanently denied scenarios

## Usage

### Automatic Permission Request

The app automatically requests notification permissions when it starts:
1. In `main.dart`, after Firebase initialization
2. Uses `addPostFrameCallback` to ensure UI is ready

### Manual Permission Request

Users can manually request permissions through:
1. The NotificationPermissionWidget
2. The NotificationPermissionScreen

### Checking Permissions

The app checks permission status:
1. Before requesting FCM token
2. When displaying permission UI
3. On user request

## Integration with FCM

The notification permission system is tightly integrated with FCM:
1. Permissions are checked before FCM token retrieval
2. Tokens are only registered when permissions are granted
3. Token refreshes maintain proper handling

## Testing

The implementation includes:
1. Permission status checking
2. Permission request handling
3. Error state management
4. Platform-specific behavior

## Future Enhancements

1. Add web notification support using Web Push API
2. Implement more granular permission controls
3. Add permission usage statistics
4. Improve error messaging for users
5. Add retry mechanisms for failed permission requests

## Troubleshooting

### Common Issues

1. **Permission Denied**: User must manually enable in app settings
2. **FCM Token Failure**: Check internet connection and Firebase configuration
3. **Platform-Specific Issues**: Refer to platform-specific documentation

### Debugging

Enable debug logging to see permission and FCM token information:
```dart
debugPrint('Notification permission status: $status');
debugPrint('FCM Registration Token: $token');
```

## Security Considerations

1. Permissions are requested only when needed
2. User consent is always required
3. No personal data is collected without permission
4. App settings redirection respects user privacy

## Performance

1. Permission checks are asynchronous and non-blocking
2. Minimal impact on app startup time
3. Efficient state management with Riverpod
4. Proper error handling prevents crashes