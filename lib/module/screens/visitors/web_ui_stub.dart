// Stub file for non-web platforms
// This provides a dummy implementation when dart:ui_web is not available

/// Stub implementation of PlatformViewRegistry for non-web platforms
class PlatformViewRegistry {
  /// No-op implementation for non-web platforms
  void registerViewFactory(String viewTypeId, dynamic Function(int) viewFactory) {
    // No-op on non-web platforms
  }
}

/// Stub implementation of platformViewRegistry for non-web platforms
/// This matches the structure of dart:ui_web which exports platformViewRegistry as a top-level variable
final platformViewRegistry = PlatformViewRegistry();

