import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;

/// A logger utility that suppresses logs in release mode for web
/// This prevents logs from appearing in the browser console in production
class AppLogger {
  /// Log a debug message (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (kIsWeb) {
        // In debug mode on web, use debugPrint
        debugPrint(message);
        if (error != null) {
          debugPrint('Error: $error');
        }
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        // On mobile, use debugPrint
        debugPrint(message);
        if (error != null) {
          debugPrint('Error: $error');
        }
        if (stackTrace != null) {
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }
    // In release mode, do nothing - logs are suppressed
  }

  /// Log an info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  /// Log a warning message (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  /// Log an error message (only in debug mode)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Log a success message (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }
}

