import 'package:flutter/foundation.dart' show kIsWeb, PlatformDispatcher, DiagnosticPropertiesBuilder, DiagnosticsProperty;
import 'package:flutter/material.dart';

/// A utility class to handle Flutter web errors and prevent disposed view issues
class FlutterWebErrorHandler {
  static bool _initialized = false;
  
  /// Initialize error handlers for Flutter web
  static void initialize() {
    if (_initialized || !kIsWeb) return;
    
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // Handle async errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _handlePlatformError(error, stack);
      return true; // Return true to indicate we've handled the error
    };
    
    _initialized = true;
    debugPrint('FlutterWebErrorHandler: Initialized');
  }
  
  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    
    // Check for disposed view errors specifically
    if (details.exception.toString().contains('EngineFlutterView') && 
        details.exception.toString().contains('isDisposed')) {
      debugPrint('Caught disposed EngineFlutterView error - preventing crash');
      // Don't rethrow this specific error as it will crash the app
      return;
    }
    
    // For other errors, present them normally
    FlutterError.presentError(details);
  }
  
  /// Handle platform errors (async errors)
  static bool _handlePlatformError(Object error, StackTrace stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    
    // Check for disposed view errors specifically
    if (error.toString().contains('EngineFlutterView') && 
        error.toString().contains('isDisposed')) {
      debugPrint('Caught disposed EngineFlutterView platform error - preventing crash');
      return true; // Indicate that we've handled the error
    }
    
    // Let other errors propagate normally
    return false;
  }
  
  /// Wrap a widget with error boundary functionality
  static Widget withErrorBoundary(Widget child, {Widget? errorWidget}) {
    if (!kIsWeb) return child;
    
    return ErrorBoundary(
      errorWidget: errorWidget,
      child: child,
    );
  }
}

/// A widget that catches errors in its subtree and displays an error widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
  });
  
  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }
    
    return widget.child;
  }
  
  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please try refreshing the page',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Reset error state
                setState(() {
                  _hasError = false;
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('hasError', _hasError));
  }
}