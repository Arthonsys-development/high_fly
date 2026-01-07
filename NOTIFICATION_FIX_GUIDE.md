# Notification Fix - All App States

## Summary
Fixed FCM notifications to work in **all three app states**: foreground, background, and terminated.

## Changes Made

### 1. Added `flutter_local_notifications` Package
- **File**: `pubspec.yaml`
- Added dependency: `flutter_local_notifications: ^18.0.1`
- This package enables displaying notifications when the app is in the foreground

### 2. Created NotificationService
- **File**: `lib/utils/notification_service.dart`
- Centralized notification handling service
- Features:
  - Initialize notification channels for Android
  - Display notifications when app is in foreground
  - Handle notification taps
  - Configure high-importance notification channel

### 3. Updated main.dart
- **File**: `lib/main.dart`
- Added comprehensive notification handling for all app states:

#### Foreground State
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Display notification using flutter_local_notifications
  NotificationService().showNotification(message);
});
```

#### Background State
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Handle notification tap when app is in background
  _handleNotificationTap(message);
});
```

#### Terminated State
```dart
RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  // Handle notification that opened the app from terminated state
  _handleNotificationTap(initialMessage);
}
```

### 4. Updated Android Configuration
- **File**: `android/app/src/main/AndroidManifest.xml`
- Added required permissions:
  - `VIBRATE` - For notification vibration
  - `RECEIVE_BOOT_COMPLETED` - For notifications after device restart
  - `WAKE_LOCK` - To wake device for notifications
  
- Added FCM metadata:
  - Default notification channel: `high_importance_channel`
  - Default notification icon
  - Default notification color

## How It Works

### Foreground (App is open and visible)
1. FCM receives notification
2. `onMessage` listener triggers
3. `NotificationService` displays local notification
4. User sees notification in notification tray
5. Tapping notification triggers `onDidReceiveNotificationResponse`

### Background (App is running but not visible)
1. FCM receives notification
2. System displays notification automatically
3. User taps notification
4. `onMessageOpenedApp` listener triggers
5. App navigates to relevant screen via `_handleNotificationTap`

### Terminated (App is completely closed)
1. FCM receives notification
2. System displays notification
3. User taps notification
4. App launches
5. `getInitialMessage` retrieves the notification
6. App navigates to relevant screen via `_handleNotificationTap`

## Testing Instructions

### 1. Test Foreground Notifications
```bash
# Run the app
flutter run

# Send a test notification from Firebase Console:
# - Go to Firebase Console > Cloud Messaging
# - Click "Send your first message"
# - Enter title and text
# - Select your app
# - Send now

# Expected: Notification appears while app is open
```

### 2. Test Background Notifications
```bash
# Run the app
flutter run

# Press home button to background the app
# Send test notification from Firebase Console

# Expected: 
# - Notification appears in notification tray
# - Tapping notification opens the app
# - Debug logs show "A notification was tapped - app was in BACKGROUND"
```

### 3. Test Terminated State Notifications
```bash
# Run the app
flutter run

# Close the app completely (swipe away from recent apps)
# Send test notification from Firebase Console

# Expected:
# - Notification appears in notification tray
# - Tapping notification launches the app
# - Debug logs show "App opened from TERMINATED state via notification"
```

## Debug Logs to Look For

All notification events are logged with 🔔 emoji for easy filtering:

```
🔔 Got a message whilst in the FOREGROUND!
🔔 Title: <notification title>
🔔 Body: <notification body>
🔔 Handling a background message: <messageId>
🔔 A notification was tapped - app was in BACKGROUND
🔔 App opened from TERMINATED state via notification
🔔 FCM Registration Token: <token>
```

## Customization

### Adding Navigation on Notification Tap
Update the `_handleNotificationTap` function in `main.dart`:

```dart
void _handleNotificationTap(RemoteMessage message) {
  debugPrint('🔔 Handling notification tap');
  
  // Extract screen/route from notification data
  final String? screen = message.data['screen'];
  final String? id = message.data['id'];
  
  if (screen != null && navigatorKey.currentState != null) {
    // Navigate to specific screen
    navigatorKey.currentState!.pushNamed(
      screen,
      arguments: id,
    );
  }
}
```

### Customizing Notification Appearance
Edit `lib/utils/notification_service.dart`:
- Change notification icon
- Modify notification sound
- Adjust vibration pattern
- Set custom notification color

## Important Notes

1. **iOS Configuration**: If testing on iOS, ensure:
   - APNs certificates are configured in Firebase Console
   - Capabilities > Push Notifications is enabled in Xcode
   - Background Modes > Remote notifications is enabled

2. **Android 13+**: Notification permission is required. The app requests it automatically on first launch.

3. **Token Registration**: FCM tokens are logged on app start. Use these tokens to send targeted notifications from your backend.

## Troubleshooting

### Notifications still not appearing in foreground
1. Check if NotificationService is initialized: Look for "✅ NotificationService initialized successfully"
2. Verify notification permission is granted
3. Check device notification settings for the app

### Notifications not appearing in background
1. Verify `google-services.json` is up to date
2. Check if background messaging handler is registered
3. Ensure app has background execution permission

### Notifications not appearing when terminated
1. Check if FCM configuration is correct in Firebase Console
2. Verify the app is registered for push notifications
3. Test with a different device or emulator

## Next Steps

1. **Test on physical device**: Notifications work better on real devices than emulators
2. **Implement navigation**: Update `_handleNotificationTap` to navigate to specific screens
3. **Backend integration**: Update your backend to send structured notification payloads with navigation data
4. **Analytics**: Add Firebase Analytics events to track notification engagement
