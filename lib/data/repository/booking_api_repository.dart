import 'dart:io';
import 'package:dio/dio.dart';
import '../../config/network/api_client.dart';
import '../../config/network/api_constants.dart';
import '../models/request_models/booking_request_model.dart';
import '../models/request_models/hold_request_model.dart';
import '../models/response_models/booking_response_model.dart';
import '../models/response_models/hold_response_model.dart';
import '../models/hold_list_model.dart';
import '../models/booking_list_model.dart';

class BookingApiRepository {
  final ApiClient _apiClient = ApiClient();

  /// Create a new plot booking with multipart/form-data
  Future<BookingResponseModel> createBooking(BookingRequestModel request) async {
    try {
      // Create FormData for multipart request
      final Map<String, dynamic> formDataMap = {...request.toFormData()};
      
      // Add files if they exist and are valid
      if (request.salarySlipPath != null && request.salarySlipPath!.isNotEmpty) {
        final salarySlipFile = File(request.salarySlipPath!);
        if (await salarySlipFile.exists()) {
          formDataMap['salary_slip'] = await MultipartFile.fromFile(
            request.salarySlipPath!,
            filename: 'salary_slip.pdf',
          );
        }
      }
      
      if (request.form16APath != null && request.form16APath!.isNotEmpty) {
        final form16AFile = File(request.form16APath!);
        if (await form16AFile.exists()) {
          formDataMap['form_16a'] = await MultipartFile.fromFile(
            request.form16APath!,
            filename: 'form_16a.pdf',
          );
        }
      }
      
      final formData = FormData.fromMap(formDataMap);

      final response = await _apiClient.postMultipart(
        ApiConstants.plotBookings,
        data: formData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookingResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create booking: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a new plot hold
  Future<HoldResponseModel> createHold(HoldRequestModel request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.plotHolds,
        data: request.toJson(),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return HoldResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create hold: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get list of all holds
  Future<List<HoldListModel>> getHoldsList() async {
    try {
      final response = await _apiClient.get(ApiConstants.holdsList);
      
      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((item) => HoldListModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch holds: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get list of all bookings
  Future<List<BookingListModel>> getBookingsList() async {
    try {
      final response = await _apiClient.get(ApiConstants.bookingsList);
      
      if (response.statusCode == 200) {
        if (response.data is List) {
          return (response.data as List)
              .map((item) => BookingListModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch bookings: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('API Error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
