import 'package:dio/dio.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/data/models/response_model/organization_response_model.dart';

class OrganizationRepository {
  OrganizationRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  static const String _organizationEndpoint =
      'http://64.227.154.65:81/api/v1/organization/';

  Future<Organization> fetchOrganization() async {
    try {
      final response = await _apiClient.get(_organizationEndpoint);
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

