import 'package:flutter/cupertino.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:highfly/data/models/customer_model.dart';
import 'package:dio/dio.dart';

class CustomerApiRepository {
  final ApiClient _apiClient = ApiClient();

  // Create customer
  Future<Map<String, dynamic>> createCustomer(String name, String phone) async {
    try {
      debugPrint('Creating customer with name: $name, phone: $phone');
      
      final requestData = {
        'name': name,
        'phone': phone,
      };
      
      final response = await _apiClient.post(
        ApiConstants.customers,
        data: requestData,
      );
      
      debugPrint('Customer creation response: ${response.data}');
      debugPrint('Response data type: ${response.data.runtimeType}');
      
      // Parse the created customer from response
      Map<String, dynamic> responseData = response.data as Map<String, dynamic>;
      debugPrint('Response data keys: ${responseData.keys.toList()}');
      debugPrint('ID field value: ${responseData['id']}');
      
      Customer createdCustomer = Customer.fromJson(responseData);
      
      return {
        'success': true,
        'data': createdCustomer,
        'message': 'Customer created successfully',
      };
    } on DioException catch (e) {
      debugPrint('Customer creation error: ${e.message}');
      debugPrint('Error response: ${e.response?.data}');
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to create customer',
      };
    } catch (e) {
      debugPrint('Unexpected error creating customer: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'An unexpected error occurred',
      };
    }
  }

  // Get all customers
  Future<Map<String, dynamic>> getCustomers() async {
    try {
      debugPrint('Fetching customers');
      
      final response = await _apiClient.get(ApiConstants.customers);
      
      debugPrint('Customers API response: ${response.data}');
      
      // Parse customers from response
      List<Customer> customers = [];
      
      if (response.data is List) {
        customers = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => Customer.fromJson(item))
            .toList();
      } else if (response.data is Map && response.data['results'] is List) {
        customers = (response.data['results'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => Customer.fromJson(item))
            .toList();
      }
      
      return {
        'success': true,
        'data': customers,
        'message': 'Customers fetched successfully',
      };
    } on DioException catch (e) {
      debugPrint('Fetch customers error: ${e.message}');
      debugPrint('Error response: ${e.response?.data}');
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to fetch customers',
      };
    } catch (e) {
      debugPrint('Unexpected error fetching customers: $e');
      
      return {
        'success': false,
        'error': e.toString(),
        'message': 'An unexpected error occurred',
      };
    }
  }
}
