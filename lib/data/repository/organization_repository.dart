import 'package:dio/dio.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:highfly/data/models/response_model/organization_response_model.dart';

class OrganizationRepository {
  OrganizationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Organization> fetchOrganization() async {
    try {
      final response = await _apiClient.get(ApiConstants.organization);
      if (response.data is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response format');
      }
      final parsed =
          OrganizationResponse.fromJson(response.data as Map<String, dynamic>);
      if (parsed.organization == null) {
        throw const FormatException('Organization data missing');
      }
      return parsed.organization!;
    } on DioException catch (e) {
      throw Exception('Failed to fetch organization: ${e.message}');
    }
  }
}

