import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Helper class for showing guest user alerts
class GuestAlertHelper {
  /// Show alert dialog for guest users with action-specific message
  static void showGuestAlert(
    BuildContext context, {
    String? message,
  }) {
    final defaultMessage = message ??
        'Guest users cannot perform this action. Please sign in with your phone number to access all features.';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Guest User',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            defaultMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 252, 254, 255),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color.fromARGB(255, 250, 253, 255),
                  fontSize: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Logout guest user before navigating to sign in
                await _logoutGuestUser();
                // Navigate to sign in screen
                if (context.mounted) {
                  context.go(Routes.signIn);
                }
              },
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Color.fromARGB(255, 25, 254, 13),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Logout guest user from Firebase and clear secure storage
  static Future<void> _logoutGuestUser() async {
    try {
      debugPrint('🚪 Logging out guest user...');
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      debugPrint('🚪 Signed out from Firebase');
      
      // Clear all secure storage
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();
      debugPrint('🚪 Cleared secure storage');
      
      debugPrint('✅ Guest user logged out successfully');
    } catch (e) {
      debugPrint('❌ Error logging out guest user: $e');
      // Continue anyway - user can still try to sign in
    }
  }
}
