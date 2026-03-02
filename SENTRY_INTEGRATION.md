# Sentry Integration Guide

## Overview
Sentry has been successfully integrated into the HighFly app for comprehensive error tracking and API monitoring. This integration captures all API calls with their parameters and responses, along with any exceptions that occur throughout the application.

## What's Integrated

### 1. Sentry Core Features
- **Error Tracking**: All exceptions and errors are automatically captured and reported to Sentry
- **Performance Monitoring**: API call performance is tracked with transaction tracing
- **Breadcrumbs**: Navigation and user actions are tracked for better debugging context
- **Release Tracking**: Errors are tagged with environment information (dev/prod)

### 2. API Monitoring
Every API call is monitored with the following details captured:

#### Request Details:
- **URL**: Full endpoint URL
- **HTTP Method**: GET, POST, PUT, PATCH, DELETE
- **Headers**: Request headers (sensitive data like tokens are redacted)
- **Query Parameters**: All query parameters
- **Request Body**: Full request payload (sensitive fields are sanitized)
- **Timestamp**: When the request was made

#### Response Details:
- **Status Code**: HTTP response status
- **Response Headers**: All response headers
- **Response Body**: Complete response data (with size limits)
- **Response Time**: Duration of the API call

#### Error Details:
- **Error Type**: Type of Dio exception (connection timeout, bad response, etc.)
- **Error Message**: Detailed error description
- **Stack Trace**: Full stack trace for debugging
- **Response Data**: Error response from the server

### 3. Data Sanitization
To protect user privacy and security, sensitive information is automatically redacted:

#### Sanitized Headers:
- `Authorization` token (shows first 4 and last 4 characters only)
- `Cookie` values
- `X-API-Key` values

#### Sanitized Data Fields:
- `password`
- `token`, `access_token`, `refresh_token`, `id_token`
- `secret`
- `api_key`
- `credit_card`, `cvv`
- `ssn`

### 4. Performance Optimization
- **Size Limits**: Response bodies larger than 5KB are truncated to prevent large payloads
- **Smart Sampling**: Transactions are sampled at 100% for comprehensive monitoring
- **Asynchronous**: All Sentry operations are non-blocking

## Files Modified

### 1. `pubspec.yaml`
Added Sentry packages:
```yaml
sentry_flutter: ^8.14.0
sentry_dio: ^8.14.0
```

### 2. `lib/config/sentry_config.dart` (NEW)
Configuration file containing:
- Sentry DSN
- Environment settings
- Sampling rates
- Feature flags

### 3. `lib/main.dart`
- Wrapped app initialization with `SentryFlutter.init()`
- Added exception capturing for all initialization errors
- Configured Sentry options

### 4. `lib/config/network/sentry_dio_interceptor.dart` (NEW)
Custom Dio interceptor that:
- Captures all API requests and responses
- Creates breadcrumbs for better context
- Starts and finishes transactions for performance monitoring
- Handles error capturing with full context
- Sanitizes sensitive data

### 5. `lib/config/network/api_client.dart`
- Added `SentryDioInterceptor` to the Dio interceptors list
- All API calls now automatically report to Sentry

## Sentry Dashboard

### DSN (Data Source Name)
```
https://b9ee3b27ca516a021f338cf7a3647278@o4510759838285824.ingest.de.sentry.io/4510945049509968
```

### How to Access
1. Visit: https://sentry.io
2. Log in with your organization credentials
3. Navigate to the HighFly project

### What You'll See

#### Issues Tab
- All exceptions and errors
- Grouped by error type
- Stack traces with source code context
- User actions leading to the error (breadcrumbs)

#### Performance Tab
- API call performance metrics
- Slow API calls
- Error rates
- Transaction traces

#### Releases Tab
- Errors grouped by app version
- Deployment tracking

## Testing the Integration

### 1. Test API Success
Make any API call in the app. Check Sentry for:
- Request details in breadcrumbs
- Response data
- Performance metrics

### 2. Test API Error
Trigger an API error (e.g., network disconnection). Check Sentry for:
- Error event with full context
- Request that caused the error
- Error response from server

### 3. Test App Crash
Cause an exception in the app. Check Sentry for:
- Exception details
- Stack trace
- Breadcrumbs showing user actions before the crash

## Configuration Options

### Adjust Sampling Rate
In `lib/config/sentry_config.dart`:
```dart
static const double tracesSampleRate = 1.0; // 100% of transactions
```

Lower to 0.5 for 50% sampling or 0.1 for 10% sampling to reduce Sentry quota usage.

### Enable/Disable PII (Personally Identifiable Information)
```dart
static const bool sendDefaultPii = false; // Currently disabled
```

Set to `true` to include user data (email, username) in Sentry reports.

### Disable Sentry in Development
In `lib/config/sentry_config.dart`:
```dart
static const bool enabled = true;
```

You can conditionally set this based on build mode:
```dart
static bool get enabled => !kDebugMode; // Only in release mode
```

## Best Practices

### 1. Monitor Sentry Quotas
- Sentry has monthly event limits based on your plan
- Monitor usage in the Sentry dashboard
- Adjust sampling rates if approaching limits

### 2. Set Up Alerts
Configure Sentry alerts to notify your team when:
- Critical errors occur
- Error rate spikes
- API response times degrade

### 3. Triage Regularly
- Review new issues daily
- Mark issues as resolved after fixing
- Ignore false positives or known issues

### 4. Use Releases
Tag your deployments with release versions to track:
- Which version introduced a bug
- Whether a fix resolved the issue
- Regression detection

## Advanced Features

### Custom Breadcrumbs
Add custom breadcrumbs for important user actions:
```dart
Sentry.addBreadcrumb(Breadcrumb(
  message: 'User clicked submit button',
  category: 'user.action',
  level: SentryLevel.info,
));
```

### Custom Tags
Tag events for better filtering:
```dart
Sentry.configureScope((scope) {
  scope.setTag('user_type', 'premium');
  scope.setTag('feature', 'checkout');
});
```

### User Context
Set user information (only if appropriate):
```dart
Sentry.configureScope((scope) {
  scope.setUser(SentryUser(
    id: 'user-id',
    email: 'user@example.com',
    username: 'john_doe',
  ));
});
```

### Manual Exception Capture
Capture specific exceptions:
```dart
try {
  // Some code
} catch (e, stackTrace) {
  Sentry.captureException(e, stackTrace: stackTrace);
  // Handle error
}
```

## Troubleshooting

### Events Not Showing in Sentry
1. Check your internet connection
2. Verify DSN is correct in `sentry_config.dart`
3. Ensure `SentryConfig.enabled` is `true`
4. Check Sentry dashboard for project status

### Too Many Events
1. Lower the `tracesSampleRate` in configuration
2. Add filters for known non-critical errors
3. Use ignore rules in Sentry dashboard

### Sensitive Data Exposure
1. Review `_sanitizeHeaders()` in the interceptor
2. Add more fields to `sensitiveKeys` list
3. Review data before reporting critical issues

## Support
For questions or issues with Sentry integration:
1. Check Sentry documentation: https://docs.sentry.io/platforms/flutter/
2. Review this guide
3. Contact the development team

## Summary
Sentry is now fully integrated and monitoring:
- ✅ All API calls with request/response details
- ✅ All exceptions and errors
- ✅ Performance metrics
- ✅ User context and breadcrumbs
- ✅ Sensitive data is sanitized
- ✅ Works across Android, iOS, and Web platforms
