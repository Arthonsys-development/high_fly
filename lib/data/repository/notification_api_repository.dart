import 'package:flutter/foundation.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:highfly/data/models/notification_model.dart';
import 'package:dio/dio.dart';

class NotificationApiRepository {
  final ApiClient _apiClient = ApiClient();

  Future<NotificationsModel> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.notifications);
      if (response.statusCode == 200 && response.data != null) {
        return NotificationsModel.fromJson(
            response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to load notifications: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('DioException fetching notifications: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }
}
