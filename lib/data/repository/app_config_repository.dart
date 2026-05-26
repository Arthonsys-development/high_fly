import 'package:dio/dio.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:highfly/data/models/app_config_model.dart';

class AppConfigRepository {
  AppConfigRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AppConfigResponse> fetchAppConfig() async {
    try {
      final response = await _apiClient.get(ApiConstants.appConfig);
      if (response.data is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response format');
      }
      return AppConfigResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Exception('Failed to fetch app config: ${e.message}');
    }
  }
}
