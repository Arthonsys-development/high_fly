import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/response_model/organization_response_model.dart';

class AppUpdateService {
  /// Check if an app update is available
  /// Returns a tuple of (isUpdateAvailable, isMandatory, updateMessage)
  static Future<(bool, bool, String?)> checkForUpdate(
    Organization? organization,
  ) async {
    if (organization?.appUpdate == null) {
      return (false, false, null);
    }

    // Get current app version
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Get platform-specific update info
    AppVersionInfo? versionInfo;
    if (kIsWeb) {
      // For web, we can check but updates are automatic
      return (false, false, null);
    } else if (Platform.isIOS) {
      versionInfo = organization?.appUpdate?.ios;
    } else if (Platform.isAndroid) {
      versionInfo = organization?.appUpdate?.android;
    }

    if (versionInfo?.version == null) {
      return (false, false, null);
    }

    // Compare versions
    final isUpdateAvailable = _isUpdateAvailable(
      currentVersion,
      versionInfo!.version!,
    );

    final isMandatory = versionInfo.isMandatoryUpdate ?? false;
    final message = versionInfo.message;

    debugPrint('🔄 App Update Check:');
    debugPrint('  Current Version: $currentVersion');
    debugPrint('  Available Version: ${versionInfo.version}');
    debugPrint('  Update Available: $isUpdateAvailable');
    debugPrint('  Mandatory: $isMandatory');
    debugPrint('  Message: $message');

    return (isUpdateAvailable, isMandatory, message);
  }

  /// Compare version strings (e.g., "1.0.1" vs "1.0.7")
  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final latest = latestVersion.split('.').map(int.parse).toList();

      // Ensure both have at least 3 parts (major.minor.patch)
      while (current.length < 3) {
        current.add(0);
      }
      while (latest.length < 3) {
        latest.add(0);
      }

      // Compare major, minor, and patch versions
      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) {
          return true;
        } else if (latest[i] < current[i]) {
          return false;
        }
      }

      return false; // Versions are equal
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  /// Show update dialog to user
  static Future<bool> showUpdateDialog({
    required BuildContext context,
    required bool isMandatory,
    String? message,
  }) async {
    final shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  isMandatory ? Icons.warning_amber : Icons.info_outline,
                  color: isMandatory ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 12),
                Text(
                  isMandatory ? 'Update Required' : 'Update Available',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message ??
                      (isMandatory
                          ? 'A new version of the app is available. Please update to continue using the app.'
                          : 'A new version of the app is available. Would you like to update now?'),
                  style: const TextStyle(fontSize: 16),
                ),
                if (isMandatory) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This update is mandatory and you cannot use the app without updating.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Later'),
                ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMandatory ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Update Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );

    return shouldUpdate ?? false;
  }

  /// Open app store for update
  static Future<void> openAppStore() async {
    if (kIsWeb) {
      // For web, just reload the page
      debugPrint('Web platform - reloading page for update');
      return;
    }

    String? url;
    if (Platform.isIOS) {
      // Replace with your actual App Store URL
      url = 'https://apps.apple.com/app/your-app-id';
    } else if (Platform.isAndroid) {
      // Replace with your actual Play Store URL
      url = 'https://play.google.com/store/apps/details?id=com.vistarak.highfly';
    }

    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    }
  }

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Get current app build number
  static Future<String> getCurrentBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
}
