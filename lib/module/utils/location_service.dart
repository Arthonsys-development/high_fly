import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Get the current location of the device
  /// Returns a map with 'latitude' and 'longitude' keys, or null if location access is denied
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // For web platform, handle permissions differently
      if (kIsWeb) {
        return await _getWebLocation();
      }

      // Check if location services are enabled (mobile only)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied, we cannot request permissions.');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } on MissingPluginException catch (e) {
      debugPrint('Geolocator plugin not properly registered: $e');
      debugPrint('Please restart the app after adding the geolocator dependency');
      return null;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Get location specifically for web platform
  Future<Map<String, double>?> _getWebLocation() async {
    try {
      debugPrint('Getting location for web platform...');
      
      // For web, directly request location permission and get position
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied on web');
        return null;
      }

      // Get current position with web-optimized settings
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Use medium accuracy for web
        timeLimit: const Duration(seconds: 20), // Longer timeout for web
      );

      debugPrint('Web location obtained: ${position.latitude}, ${position.longitude}');
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      debugPrint('Error getting web location: $e');
      return null;
    }
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  /// Calculate distance between two coordinates in meters
  /// Returns distance in meters, or null if calculation fails
  double? calculateDistance(
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
  ) {
    try {
      if (startLatitude == null || startLongitude == null || 
          endLatitude == null || endLongitude == null) {
        return null;
      }
      
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return null;
    }
  }

  /// Check if user is within specified distance from project location
  /// Returns true if within distance, false if outside, null if calculation fails
  bool? isWithinDistance(
    double? userLatitude,
    double? userLongitude,
    double? projectLatitude,
    double? projectLongitude,
    double maxDistanceInMeters,
  ) {
    final distance = calculateDistance(
      userLatitude,
      userLongitude,
      projectLatitude,
      projectLongitude,
    );
    
    if (distance == null) {
      return null;
    }
    
    return distance <= maxDistanceInMeters;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      if (kIsWeb) {
        // For web, we assume location services are available if the browser supports it
        return true;
      }
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Open location settings if location services are disabled
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings if location permission is denied
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
