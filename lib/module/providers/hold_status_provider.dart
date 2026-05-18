import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:highfly/data/models/hold_status_model.dart';
import 'package:dio/dio.dart';

final holdStatusProvider = FutureProvider<HoldStatusModel>((ref) async {
  try {
    final apiClient = ApiClient();
    final response = await apiClient.dio.get(ApiConstants.holdStatus);
    if (response.statusCode == 200 && response.data != null) {
      return HoldStatusModel.fromJson(response.data as Map<String, dynamic>);
    }
    return HoldStatusModel.permissive;
  } on DioException catch (e) {
    debugPrint('holdStatusProvider: DioException: ${e.message}');
    return HoldStatusModel.permissive;
  } catch (e) {
    debugPrint('holdStatusProvider: Error: $e');
    return HoldStatusModel.permissive;
  }
});
