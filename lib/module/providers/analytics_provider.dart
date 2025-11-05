import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Analytics provider
final analyticsProvider = Provider<FirebaseAnalyticsService>((ref) {
  return FirebaseAnalyticsService();
});

class FirebaseAnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        debugPrint('📊 Analytics: Logged event "$name" with parameters: $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics: Error logging event "$name": $e');
      }
    }
  }

  /// Log visit creation
  Future<void> logVisitCreated({
    required String visitType,
    required String projectId,
    String? projectName,
    bool hasPhoto = true,
    bool hasComments = false,
  }) async {
    await logEvent(
      name: 'visit_created',
      parameters: {
        'visit_type': visitType,
        'project_id': projectId,
        if (projectName != null) 'project_name': projectName,
        'has_photo': hasPhoto,
        'has_comments': hasComments,
      },
    );
  }

  /// Log user login
  Future<void> logLogin({String? method}) async {
    await logEvent(
      name: 'login',
      parameters: {
        if (method != null) 'method': method,
      },
    );
  }

  /// Log user signup
  Future<void> logSignUp({String? method}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {
        if (method != null) 'method': method,
      },
    );
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      if (kDebugMode) {
        debugPrint('📊 Analytics: Logged screen view "$screenName"');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics: Error logging screen view "$screenName": $e');
      }
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        debugPrint('📊 Analytics: Set user property "$name" = "$value"');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics: Error setting user property "$name": $e');
      }
    }
  }

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        debugPrint('📊 Analytics: Set user ID "$userId"');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Analytics: Error setting user ID: $e');
      }
    }
  }

  /// Log project view
  Future<void> logProjectViewed({
    required String projectId,
    String? projectName,
  }) async {
    await logEvent(
      name: 'project_viewed',
      parameters: {
        'project_id': projectId,
        if (projectName != null) 'project_name': projectName,
      },
    );
  }

  /// Log dashboard viewed
  Future<void> logDashboardViewed() async {
    await logScreenView(screenName: 'dashboard');
  }
}

