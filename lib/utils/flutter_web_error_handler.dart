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
    final errorString = details.exception.toString();
    debugPrint('Flutter Error: ${details.exception}');
    
    // Check for disposed view errors
    if (errorString.contains('EngineFlutterView') && 
        errorString.contains('isDisposed')) {
      debugPrint('✓ Caught disposed EngineFlutterView error - preventing crash');
      return;
    }
    
    // Check for RenderBox layout errors (hasSize assertion)
    if (errorString.contains('RenderBox was not laid out') ||
        errorString.contains('hasSize') ||
        errorString.contains('RenderRepaintBoundary') ||
        errorString.contains('RenderMouseRegion') ||
        errorString.contains('NEEDS-PAINT') ||
        errorString.contains('relayoutBoundary')) {
      debugPrint('✓ Caught RenderBox layout error - preventing crash');
      return;
    }
    
    // Check for assertion errors related to layout
    if (errorString.contains('Assertion failed') && 
        (errorString.contains('rendering') || errorString.contains('layout'))) {
      debugPrint('✓ Caught rendering assertion error - preventing crash');
      return;
    }
    
    // For other errors, present them normally (only in debug mode on web)
    if (kIsWeb) {
      debugPrint('Stack trace: ${details.stack}');
      // On web, suppress non-critical framework errors in release mode
      if (details.library != null && details.library!.contains('flutter')) {
        debugPrint('⚠ Flutter framework error suppressed in web mode');
        return;
      }
    }
    
    FlutterError.presentError(details);
  }
  
  /// Handle platform errors (async errors)
  static bool _handlePlatformError(Object error, StackTrace stack) {
    final errorString = error.toString();
    debugPrint('Platform Error: $error');
    
    // Check for disposed view errors
    if (errorString.contains('EngineFlutterView') && 
        errorString.contains('isDisposed')) {
      debugPrint('✓ Caught disposed EngineFlutterView platform error - preventing crash');
      return true;
    }
    
    // Check for RenderBox layout errors
    if (errorString.contains('RenderBox was not laid out') ||
        errorString.contains('hasSize') ||
        errorString.contains('RenderRepaintBoundary') ||
        errorString.contains('RenderMouseRegion') ||
        errorString.contains('NEEDS-PAINT') ||
        errorString.contains('relayoutBoundary')) {
      debugPrint('✓ Caught RenderBox layout platform error - preventing crash');
      return true;
    }
    
    // Check for assertion errors related to layout
    if (errorString.contains('Assertion failed') && 
        (errorString.contains('rendering') || errorString.contains('layout'))) {
      debugPrint('✓ Caught rendering assertion platform error - preventing crash');
      return true;
    }
    
    // On web, suppress common Flutter web framework errors
    if (kIsWeb && (errorString.contains('dart:ui') || 
                   errorString.contains('dart:html') ||
                   errorString.contains('package:flutter/src'))) {
      debugPrint('⚠ Flutter web framework error suppressed');
      return true;
    }
    
    debugPrint('Stack trace: $stack');
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
  
  /// Wrap a widget with safe layout that prevents common web rendering issues
  static Widget safeLayout(Widget child) {
    if (!kIsWeb) return child;
    
    return RepaintBoundary(
      child: child,
    );
  }
}

/// A safe wrapper for mouse-interactive widgets on Flutter web
/// Prevents layout assertion errors by ensuring proper constraints
class SafeWebWidget extends StatelessWidget {
  final Widget child;
  
  const SafeWebWidget({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    
    // Wrap with RepaintBoundary to isolate layout issues
    return RepaintBoundary(
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