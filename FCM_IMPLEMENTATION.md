# FCM (Firebase Cloud Messaging) Implementation

## Overview

This document describes the Firebase Cloud Messaging (FCM) implementation in the HighFly application. The implementation includes:

1. Getting FCM tokens
2. Registering devices with the backend
3. Handling token refreshes
4. Supporting both mobile and web platforms

## Implementation Details

### Dependencies Added

The following dependencies were added to `pubspec.yaml`:

```yaml
firebase_messaging: ^15.1.5
```

### Android Configuration

Added Firebase Messaging to `android/app/build.gradle.kts`:

```kotlin
implementation("com.google.firebase:firebase-messaging")
```

### iOS Configuration

CocoaPods automatically handles iOS dependencies when `pod install` is run.

### Web Configuration

Added Firebase Messaging SDK to `web/index.html`:

```html
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js"></script>
```

## Code Structure

### 1. FCM Provider (`lib/module/providers/fcm_provider.dart`)

The FCM provider manages the FCM token state and provides methods to:

- Get the FCM token
- Register the token with the backend
- Listen for token refreshes

#### Key Methods:

- `getFcmToken()`: Gets the current FCM token and registers it with the backend
- `_registerToken(String token)`: Sends the token to the backend API
- `listenForTokenRefresh()`: Listens for token refreshes and updates the backend

### 2. Auth API Repository Enhancement (`lib/data/repository/auth_api_repository.dart`)

Added a new method to register devices for notifications:

```dart
Future<Map<String, dynamic>> registerDeviceForNotifications(NotificationRegisterRequestModel request)
```

### 3. Main Application Initialization (`lib/main.dart`)

FCM is initialized in the main function:

- Requests notification permissions (iOS)
- Sets up background message handling
- Gets the initial FCM token
- Sets up token refresh listeners

The FCM provider is also initialized in the [MyApp] widget's build method using `addPostFrameCallback`.

## API Integration

### Notification Registration Model

The `NotificationRegisterRequestModel` is used to send device information to the backend:

```dart
class NotificationRegisterRequestModel {
  final String registrationToken;
  final String deviceType; // 'android', 'ios', or 'web'
}
```

### API Endpoint

The notifications are registered using the existing endpoint:
```
POST /notifications/register-device/
```

## Platform Support

### Mobile (Android/iOS)

Full FCM support with:
- Token management
- Background message handling
- Token refresh handling

### Web

Limited support - FCM token registration is skipped on web platform with a message indicating it's not supported.

## Usage

The FCM token registration happens automatically when the app starts. The process:

1. App initializes Firebase Messaging
2. Requests FCM token
3. Sends token to backend API
4. Listens for token refreshes and updates backend

## Testing

A basic test file is included at `test/fcm_test.dart` to verify the provider functionality.

## Troubleshooting

### Common Issues

1. **"FCM not supported on web platform"**: This is expected behavior as the current implementation doesn't support web
2. **Permission denied**: On iOS, users must grant notification permissions
3. **Token not received**: Check Firebase project configuration and internet connectivity

### Debugging

Enable debug logging to see FCM token information:
```dart
debugPrint('FCM Registration Token: $token');
```

## Future Enhancements

1. Add web support for FCM
2. Implement background message handling
3. Add more comprehensive error handling
4. Implement token caching to reduce API calls