/// Sentry configuration for error tracking and monitoring
class SentryConfig {
  // Sentry DSN for the project
  static const String dsn = 'https://b9ee3b27ca516a021f338cf7a3647278@o4510759838285824.ingest.de.sentry.io/4510945049509968';
  
  // Environment name (can be overridden based on build mode)
  static String get environment {
    // You can customize this based on your environment
    // For example, return 'dev' or 'prod' based on your build configuration
    return const String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
  }
  
  // Enable/disable Sentry (can be controlled via environment variables)
  static const bool enabled = true;
  
  // Sample rate for performance monitoring (0.0 to 1.0)
  // 1.0 means 100% of transactions are sent to Sentry
  static const double tracesSampleRate = 1.0;
  
  // Note: Breadcrumbs are automatically enabled by default in Sentry Flutter
  // This includes navigation, user interactions, HTTP requests, etc.
  
  // Attach screenshots on errors
  static const bool attachScreenshot = true;
  
  // Send default PII (Personally Identifiable Information)
  // Set to false if you don't want to send user data
  static const bool sendDefaultPii = false;
}
