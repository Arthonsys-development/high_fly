import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to manage reCAPTCHA Enterprise site keys in the app.
///
/// Site keys are loaded from .env files.
/// Update RECAPTCHA_SITE_KEY_ANDROID and RECAPTCHA_SITE_KEY_IOS in your .env file.
class RecaptchaConfig {
  RecaptchaConfig._();

  /// Gets the reCAPTCHA Enterprise site key for the current platform.
  /// Returns Android key for Android, iOS key for iOS.
  /// Throws an exception if the key is not found.
  static String get siteKey {
    try {
      final key = Platform.isAndroid
          ? androidSiteKey
          : Platform.isIOS
              ? iosSiteKey
              : throw UnsupportedError('reCAPTCHA Enterprise is only supported on Android and iOS');
      
      if (kDebugMode) {
        debugPrint('RecaptchaConfig: Using ${Platform.isAndroid ? "Android" : "iOS"} site key');
      }
      
      return key;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RecaptchaConfig: Error getting site key: $e');
      }
      rethrow;
    }
  }

  /// Gets the Android reCAPTCHA Enterprise site key from environment variables.
  static String get androidSiteKey {
    final key = dotenv.env['RECAPTCHA_SITE_KEY_ANDROID'];
    
    if (key == null || key.isEmpty) {
      throw Exception(
        'RECAPTCHA_SITE_KEY_ANDROID not found in environment variables. '
        'Please add it to your .env file.'
      );
    }
    
    if (kDebugMode) {
      debugPrint('RecaptchaConfig: Android site key loaded from env');
    }
    
    return key;
  }

  /// Gets the iOS reCAPTCHA Enterprise site key from environment variables.
  static String get iosSiteKey {
    final key = dotenv.env['RECAPTCHA_SITE_KEY_IOS'];
    
    if (key == null || key.isEmpty) {
      throw Exception(
        'RECAPTCHA_SITE_KEY_IOS not found in environment variables. '
        'Please add it to your .env file.'
      );
    }
    
    if (kDebugMode) {
      debugPrint('RecaptchaConfig: iOS site key loaded from env');
    }
    
    return key;
  }
}
