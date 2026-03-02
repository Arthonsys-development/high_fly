import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Custom Sentry Dio Interceptor for comprehensive API monitoring
/// 
/// This interceptor captures:
/// - All API request details (URL, method, headers, parameters, body)
/// - All API response details (status code, headers, response data)
/// - Any exceptions that occur during API calls
class SentryDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Create breadcrumb for the request
    final breadcrumb = Breadcrumb(
      type: 'http',
      category: 'http.request',
      data: {
        'url': options.uri.toString(),
        'method': options.method,
        'headers': _sanitizeHeaders(options.headers),
        'query_parameters': options.queryParameters,
      },
      level: SentryLevel.info,
    );
    
    Sentry.addBreadcrumb(breadcrumb);
    
    // Create a custom transaction for performance monitoring
    final transaction = Sentry.startTransaction(
      '${options.method} ${options.path}',
      'http.client',
      bindToScope: true,
    );
    
    // Store transaction in request options for later use
    options.extra['sentry_transaction'] = transaction;
    
    // Log request details to Sentry as context
    Sentry.configureScope((scope) {
      scope.setContexts('api_request', {
        'url': options.uri.toString(),
        'method': options.method,
        'headers': _sanitizeHeaders(options.headers),
        'query_parameters': options.queryParameters.toString(),
        'request_body': _sanitizeData(options.data),
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    
    debugPrint('🔍 Sentry: Tracking API request - ${options.method} ${options.uri}');
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Finish the transaction
    final transaction = response.requestOptions.extra['sentry_transaction'] as ISentrySpan?;
    transaction?.finish(status: SpanStatus.ok());
    
    // Create breadcrumb for the response
    final breadcrumb = Breadcrumb(
      type: 'http',
      category: 'http.response',
      data: {
        'url': response.requestOptions.uri.toString(),
        'method': response.requestOptions.method,
        'status_code': response.statusCode,
        'response_headers': _sanitizeHeaders(response.headers.map),
        'response_body': _sanitizeData(response.data),
      },
      level: SentryLevel.info,
    );
    
    Sentry.addBreadcrumb(breadcrumb);
    
    // Log response details to Sentry
    Sentry.configureScope((scope) {
      scope.setContexts('api_response', {
        'url': response.requestOptions.uri.toString(),
        'method': response.requestOptions.method,
        'status_code': response.statusCode,
        'response_headers': _sanitizeHeaders(response.headers.map),
        'response_body': _sanitizeData(response.data),
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
    
    // Capture event for successful API call (optional - for comprehensive logging)
    // You can comment this out if you only want to track errors
    _captureApiEvent(
      response.requestOptions,
      response: response,
      isError: false,
    );
    
    debugPrint('🔍 Sentry: API response captured - ${response.statusCode}');
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Finish the transaction with error status
    final transaction = err.requestOptions.extra['sentry_transaction'] as ISentrySpan?;
    transaction?.finish(status: SpanStatus.fromHttpStatusCode(err.response?.statusCode ?? 500));
    
    // Create breadcrumb for the error
    final breadcrumb = Breadcrumb(
      type: 'http',
      category: 'http.error',
      data: {
        'url': err.requestOptions.uri.toString(),
        'method': err.requestOptions.method,
        'error_type': err.type.toString(),
        'error_message': err.message,
        'status_code': err.response?.statusCode,
        'response_data': _sanitizeData(err.response?.data),
      },
      level: SentryLevel.error,
    );
    
    Sentry.addBreadcrumb(breadcrumb);
    
    // Capture the exception with full context
    _captureApiException(err);
    
    debugPrint('🔍 Sentry: API error captured - ${err.message}');
    
    handler.next(err);
  }
  
  /// Capture API event to Sentry with full context
  void _captureApiEvent(
    RequestOptions requestOptions, {
    Response? response,
    required bool isError,
  }) {
    final event = SentryEvent(
      level: isError ? SentryLevel.error : SentryLevel.info,
      message: SentryMessage(
        '${requestOptions.method} ${requestOptions.uri}',
      ),
      tags: {
        'api.method': requestOptions.method,
        'api.endpoint': requestOptions.path,
        'api.status': isError ? 'error' : 'success',
      },
      contexts: Contexts(
        operatingSystem: SentryOperatingSystem(name: kIsWeb ? 'web' : 'mobile'),
      ),
      extra: {
        'request': {
          'url': requestOptions.uri.toString(),
          'method': requestOptions.method,
          'headers': _sanitizeHeaders(requestOptions.headers),
          'query_parameters': requestOptions.queryParameters.toString(),
          'request_body': _sanitizeData(requestOptions.data),
        },
        if (response != null)
          'response': {
            'status_code': response.statusCode,
            'headers': _sanitizeHeaders(response.headers.map),
            'body': _sanitizeData(response.data),
          },
      },
    );
    
    Sentry.captureEvent(event);
  }
  
  /// Capture API exception to Sentry with full context
  void _captureApiException(DioException error) {
    Sentry.captureException(
      error,
      stackTrace: error.stackTrace,
      hint: Hint.withMap({
        'request': {
          'url': error.requestOptions.uri.toString(),
          'method': error.requestOptions.method,
          'headers': _sanitizeHeaders(error.requestOptions.headers),
          'query_parameters': error.requestOptions.queryParameters.toString(),
          'request_body': _sanitizeData(error.requestOptions.data),
        },
        'response': {
          'status_code': error.response?.statusCode,
          'headers': _sanitizeHeaders(error.response?.headers.map ?? {}),
          'body': _sanitizeData(error.response?.data),
        },
        'error': {
          'type': error.type.toString(),
          'message': error.message,
        },
      }),
    );
  }
  
  /// Sanitize headers by removing sensitive information
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    
    // List of sensitive header keys to redact
    const sensitiveKeys = [
      'authorization',
      'Authorization',
      'cookie',
      'Cookie',
      'x-api-key',
      'X-API-Key',
    ];
    
    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        final value = sanitized[key]?.toString() ?? '';
        // Redact but show partial value for debugging
        if (value.length > 10) {
          sanitized[key] = '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
        } else {
          sanitized[key] = '[REDACTED]';
        }
      }
    }
    
    return sanitized;
  }
  
  /// Sanitize data by removing sensitive information and limiting size
  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;
    
    try {
      // Convert to string and limit size to prevent large payloads
      final dataString = data.toString();
      const maxLength = 5000; // 5KB limit
      
      if (dataString.length > maxLength) {
        return '${dataString.substring(0, maxLength)}... [TRUNCATED - ${dataString.length} chars total]';
      }
      
      // Try to parse as Map to sanitize sensitive fields
      if (data is Map) {
        final sanitized = Map<String, dynamic>.from(data);
        
        // List of sensitive field keys to redact
        const sensitiveKeys = [
          'password',
          'Password',
          'token',
          'Token',
          'access_token',
          'refresh_token',
          'id_token',
          'secret',
          'Secret',
          'api_key',
          'apiKey',
          'credit_card',
          'creditCard',
          'cvv',
          'ssn',
        ];
        
        for (final key in sensitiveKeys) {
          if (sanitized.containsKey(key)) {
            sanitized[key] = '[REDACTED]';
          }
        }
        
        return sanitized;
      }
      
      return data;
    } catch (e) {
      return '[SANITIZATION ERROR: ${e.toString()}]';
    }
  }
}
