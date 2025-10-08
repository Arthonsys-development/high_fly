import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:permission_handler/permission_handler.dart';
import 'package:highfly/data/repository/auth_api_repository.dart';
import 'package:highfly/data/models/request_models/notification_register_request_model.dart';
import 'package:highfly/data/repository/auth_api_repository_provider.dart';

// FCM functions provider
final fcmProvider = Provider<FcmService>((ref) {
  final authApiRepository = ref.watch(authApiRepositoryProvider);
  return FcmService(authApiRepository);
});

class FcmService {
  final AuthApiRepository _authApiRepository;

  FcmService(this._authApiRepository);

  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) {
      // Notification permissions are handled differently on web
      return false;
    }

    try {
      // Check current permission status
      var status = await Permission.notification.status;
      
      if (status.isGranted) {
        return true;
      }

      // Request permission
      status = await Permission.notification.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Open app settings if permission is permanently denied
        await openAppSettings();
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Check if notification permission is granted
  Future<bool> checkNotificationPermission() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  // Get FCM token (only if permission is granted)
  Future<String?> getFcmToken() async {
    if (kIsWeb) {
      // Firebase Messaging is not supported on web in this implementation
      return null;
    }

    try {
      // Check if we have notification permission
      final hasPermission = await checkNotificationPermission();
      if (!hasPermission) {
        // Try to request permission
        final permissionGranted = await requestNotificationPermission();
        if (!permissionGranted) {
          return null;
        }
      }

      // Request permission for notifications (iOS specific)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Get the FCM token
      final String? token = await FirebaseMessaging.instance.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  // Register FCM token with backend
  Future<bool> registerToken(String token) async {
    try {
      final deviceType = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios');
      final request = NotificationRegisterRequestModel(
        registrationToken: token,
        deviceType: deviceType,
      );
      
      final result = await _authApiRepository.registerDeviceForNotifications(request);
      return result['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Listen for token refresh
  void listenForTokenRefresh(Function(String) onTokenRefresh) {
    if (kIsWeb) return;
    
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      onTokenRefresh(newToken);
    });
  }


  void showNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Enable Notifications"),
        content: const Text(
          "Notifications are currently disabled. Please enable them in Settings "
              "to stay updated with alerts and updates.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AppSettings.openAppSettings(type: AppSettingsType.notification); // Opens notification settings
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

}