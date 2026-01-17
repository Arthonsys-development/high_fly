import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to manage BASE_URL in the app.
///
/// BASE_URL values are loaded from .env files.
/// Update BASE_URL in your .env file to switch between environments.
class BaseUrlConfig {
  BaseUrlConfig._();

  /// Gets the API base URL from environment variables.
  /// Falls back to production URL if not set in .env or if running on web.
  static String get apiBaseUrl {
    try {
      // Check if dotenv is loaded and has BASE_URL
      final baseUrlFromEnv = dotenv.env['BASE_URL'];
      
      if (baseUrlFromEnv != null && baseUrlFromEnv.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('BaseUrlConfig: Using base URL from env: $baseUrlFromEnv');
        }
        return baseUrlFromEnv;
      } else {
        // If BASE_URL is not set or empty, use fallback
        if (kDebugMode) {
          debugPrint('BaseUrlConfig: BASE_URL not found in env or empty, using fallback');
        }
        return _getFallbackBaseUrl();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BaseUrlConfig: Error getting BASE_URL from environment: $e');
      }
      return _getFallbackBaseUrl();
    }
  }

  /// Gets the image base URL from environment variables.
  /// Falls back to API base URL if BASE_URL_IMAGE is not set.
  static String get imageBaseUrl {
    try {
      final imageUrlFromEnv = dotenv.env['BASE_URL_IMAGE'];
      
      if (imageUrlFromEnv != null && imageUrlFromEnv.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('BaseUrlConfig: Using image base URL from env: $imageUrlFromEnv');
        }
        return imageUrlFromEnv;
      } else {
        // Fallback to API base URL if BASE_URL_IMAGE is not set
        if (kDebugMode) {
          debugPrint('BaseUrlConfig: BASE_URL_IMAGE not found, using API base URL as fallback');
        }
        return apiBaseUrl;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BaseUrlConfig: Error getting BASE_URL_IMAGE from environment: $e');
      }
      return apiBaseUrl;
    }
  }

  /// Gets the fallback base URL based on environment.
  /// Returns production URL for 'prod' environment, otherwise development URL.
  /// For web platform, defaults to production URL if baseUrl is empty.
  static String _getFallbackBaseUrl() {
    final env = dotenv.env['ENVIRONMENT'] ?? 'dev';
    
    // For web platform, if baseUrl is empty, use production URL
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint('BaseUrlConfig: Web platform detected, using production URL as fallback');
      }
      return _productionBaseUrl;
    }
    
    final fallbackUrl = env == 'prod' 
      ? _productionBaseUrl 
      : _developmentBaseUrl;
    
    if (kDebugMode) {
      debugPrint('BaseUrlConfig: Using fallback base URL for $env: $fallbackUrl');
    }
    
    return fallbackUrl;
  }

  /// Production API base URL
  static const String _productionBaseUrl = 'https://dashboard.vistarakgroup.com/api/v1/';
  
  /// Development API base URL
  static const String _developmentBaseUrl = 'http://223.184.0.44:83/api/v1/';

  /// Method to build full image URL from a relative path.
  /// Returns the URL as-is if it's already a full URL (starts with http:// or https://).
  static String buildImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    
    // If it's already a full URL, return as-is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    
    // Otherwise, prepend the image base URL
    final baseUrl = imageBaseUrl;
    // Ensure base URL ends with '/' if it doesn't already
    final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    // Remove leading '/' from relative path if present
    final normalizedPath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    
    return '$normalizedBaseUrl$normalizedPath';
  }

  /// Method to update base URL in environment variables.
  /// Useful for runtime URL updates.
  static void updateApiBaseUrl(String newBaseUrl) {
    if (kDebugMode) {
      debugPrint('BaseUrlConfig: Updating API base URL to: $newBaseUrl');
    }
    dotenv.env['BASE_URL'] = newBaseUrl;
  }

  /// Method to update image base URL in environment variables.
  /// Useful for runtime URL updates.
  static void updateImageBaseUrl(String newImageBaseUrl) {
    if (kDebugMode) {
      debugPrint('BaseUrlConfig: Updating image base URL to: $newImageBaseUrl');
    }
    dotenv.env['BASE_URL_IMAGE'] = newImageBaseUrl;
  }
}
