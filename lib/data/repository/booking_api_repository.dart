import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/network/api_client.dart';
import '../../config/network/api_constants.dart';
import '../models/request_models/booking_request_model.dart';
import '../models/request_models/hold_request_model.dart';
import '../models/response_models/booking_response_model.dart';
import '../models/response_models/hold_response_model.dart';
import '../models/hold_list_model.dart';
import '../models/booking_list_model.dart';

// Conditional import for File - only available on mobile platforms
import 'dart:io' if (dart.library.html) 'file_stub.dart' show File;

class BookingApiRepository {
  final ApiClient _apiClient = ApiClient();

  static const String _noInternetMessage =
      'No internet connection. Please try again later.';

  bool _isNetworkFailure(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }

    final errorText = '${e.message ?? ''} ${e.error ?? ''}'.toLowerCase();
    return errorText.contains('connection refused') ||
        errorText.contains('failed host lookup') ||
        errorText.contains('socketexception') ||
        errorText.contains('network is unreachable') ||
        errorText.contains('connection closed') ||
        errorText.contains('failed to connect');
  }

  /// True when booking create must use multipart (binary file parts).
  bool _createBookingNeedsMultipart(
    BookingRequestModel request,
    List<Map<String, dynamic>>? documentFiles,
  ) {
    if (request.chequeImageBytes != null && request.chequeImageBytes!.isNotEmpty) {
      return true;
    }
    if (request.rtgsImageBytes != null && request.rtgsImageBytes!.isNotEmpty) {
      return true;
    }
    if (request.upiImageBytes != null && request.upiImageBytes!.isNotEmpty) {
      return true;
    }
    if (documentFiles != null && documentFiles.isNotEmpty) {
      return true;
    }
    if (request.documents != null && request.documents!.isNotEmpty) {
      return true;
    }
    if (!kIsWeb) {
      final slip = request.salarySlipPath;
      if (slip != null && slip.isNotEmpty && !slip.startsWith('http')) {
        return true;
      }
      final f16 = request.form16APath;
      if (f16 != null && f16.isNotEmpty && !f16.startsWith('http')) {
        return true;
      }
    }
    return false;
  }

  bool _createHoldNeedsMultipart(
    HoldRequestModel request,
    List<Map<String, dynamic>>? documentFiles,
  ) {
    if (documentFiles != null && documentFiles.isNotEmpty) {
      return true;
    }
    if (request.documents != null && request.documents!.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Extract error message from DioException response
  /// Handles various error response formats:
  /// - Field-based errors: {"agent": ["message"]}
  /// - Simple message: {"message": "error message"}
  /// - Nested errors: {"errors": {...}}
  /// - String errors: "error message"
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final errorData = e.response!.data;
      
      // Handle Map<String, dynamic> error responses
      if (errorData is Map<String, dynamic>) {
        // Check for field-based errors (e.g., {"agent": ["message"]})
        for (var entry in errorData.entries) {
          if (entry.value is List && (entry.value as List).isNotEmpty) {
            // Return the first error message from the list
            return (entry.value as List).first.toString();
          } else if (entry.value is String) {
            // Return string value directly
            return entry.value as String;
          }
        }
        
        // Check for simple message field
        if (errorData.containsKey('message')) {
          if (errorData['message'] is String) {
            return errorData['message'] as String;
          } else if (errorData['message'] is List && (errorData['message'] as List).isNotEmpty) {
            return (errorData['message'] as List).first.toString();
          }
        }
        
        // Check for errors field (nested structure)
        if (errorData.containsKey('errors')) {
          final errors = errorData['errors'];
          if (errors is Map<String, dynamic>) {
            for (var entry in errors.entries) {
              if (entry.value is List && (entry.value as List).isNotEmpty) {
                return (entry.value as List).first.toString();
              }
            }
          }
        }
      }
      
      // Handle string error responses
      if (errorData is String) {
        return errorData;
      }
    }
    
    // Fallback to Dio's error message
    return e.message ?? 'An unknown error occurred';
  }

  /// Create a new plot booking with multipart/form-data
  /// [documentFiles] is optional list of file data (bytes + names) for web uploads
  Future<BookingResponseModel> createBooking(
    BookingRequestModel request, {
    List<Map<String, dynamic>>? documentFiles,
  }) async {
    try {
      if (request.plotIds.isEmpty) {
        throw Exception('plot_ids is required: select at least one plot.');
      }
      // JSON body (plot_ids as native array) when no file uploads — matches API examples.
      if (!_createBookingNeedsMultipart(request, documentFiles)) {
        debugPrint('createBooking JSON plot_ids=${request.plotIds}');
        final response = await _apiClient.post(
          ApiConstants.plotBookings,
          data: request.toJson(),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return BookingResponseModel.fromJson(response.data);
        }
        throw Exception('Failed to create booking: ${response.statusMessage}');
      }

      debugPrint('createBooking multipart plot_ids=${request.plotIds} (plot_ids as JSON string)');

      // Create FormData for multipart request
      final Map<String, dynamic> formDataMap = {...request.toFormData()};
      
      // Add files if they exist and are valid
      if (request.salarySlipPath != null && request.salarySlipPath!.isNotEmpty) {
        // On web, file paths are just filenames, not real paths
        if (kIsWeb) {
          // On web, if it's a URL, just pass it as a string
          if (request.salarySlipPath!.startsWith('http')) {
            formDataMap['salary_slip_path'] = request.salarySlipPath;
          }
          // Otherwise, skip - web files need to be handled with file bytes
          // For now, we'll skip file upload on web if it's not a URL
        } else {
          // On mobile, use File API
          try {
            final salarySlipFile = File(request.salarySlipPath!);
            if (await salarySlipFile.exists()) {
              formDataMap['salary_slip'] = await MultipartFile.fromFile(
                request.salarySlipPath!,
                filename: 'salary_slip.pdf',
              );
            }
          } catch (e) {
            // File doesn't exist or can't be accessed, skip
          }
        }
      }
      
      if (request.form16APath != null && request.form16APath!.isNotEmpty) {
        // On web, file paths are just filenames, not real paths
        if (kIsWeb) {
          // On web, if it's a URL, just pass it as a string
          if (request.form16APath!.startsWith('http')) {
            formDataMap['form_16a_path'] = request.form16APath;
          }
          // Otherwise, skip - web files need to be handled with file bytes
          // For now, we'll skip file upload on web if it's not a URL
        } else {
          // On mobile, use File API
          try {
            final form16AFile = File(request.form16APath!);
            if (await form16AFile.exists()) {
              formDataMap['form_16a'] = await MultipartFile.fromFile(
                request.form16APath!,
                filename: 'form_16a.pdf',
              );
            }
          } catch (e) {
            // File doesn't exist or can't be accessed, skip
          }
        }
      }

      if (request.chequeImageBytes != null && request.chequeImageBytes!.isNotEmpty) {
        final chequeImageName = request.chequeImageName ?? 'cheque_image.jpg';
        final chequeImageExtension = chequeImageName.split('.').last.toLowerCase();
        String? contentType;
        if (chequeImageExtension == 'jpg' || chequeImageExtension == 'jpeg') {
          contentType = 'image/jpeg';
        } else if (chequeImageExtension == 'png') {
          contentType = 'image/png';
        }

        formDataMap['cheque_copy'] = MultipartFile.fromBytes(
          request.chequeImageBytes!,
          filename: chequeImageName,
          contentType: contentType != null ? MediaType.parse(contentType) : null,
        );
      }

      if (request.rtgsImageBytes != null && request.rtgsImageBytes!.isNotEmpty) {
        final rtgsImageName = request.rtgsImageName ?? 'rtgs_image.jpg';
        final rtgsImageExtension = rtgsImageName.split('.').last.toLowerCase();
        String? contentType;
        if (rtgsImageExtension == 'jpg' || rtgsImageExtension == 'jpeg') {
          contentType = 'image/jpeg';
        } else if (rtgsImageExtension == 'png') {
          contentType = 'image/png';
        }

        formDataMap['rtgs_image'] = MultipartFile.fromBytes(
          request.rtgsImageBytes!,
          filename: rtgsImageName,
          contentType: contentType != null ? MediaType.parse(contentType) : null,
        );
      }

      if (request.upiImageBytes != null && request.upiImageBytes!.isNotEmpty) {
        final upiImageName = request.upiImageName ?? 'upi_image.jpg';
        final upiImageExtension = upiImageName.split('.').last.toLowerCase();
        String? contentType;
        if (upiImageExtension == 'jpg' || upiImageExtension == 'jpeg') {
          contentType = 'image/jpeg';
        } else if (upiImageExtension == 'png') {
          contentType = 'image/png';
        }

        formDataMap['upi_image'] = MultipartFile.fromBytes(
          request.upiImageBytes!,
          filename: upiImageName,
          contentType: contentType != null ? MediaType.parse(contentType) : null,
        );
      }

      // Drop path-only fields when the real multipart file is attached
      final hasSalarySlipFile =
          formDataMap.containsKey('salary_slip') && formDataMap['salary_slip'] is MultipartFile;
      final hasForm16AFile =
          formDataMap.containsKey('form_16a') && formDataMap['form_16a'] is MultipartFile;
      final hasChequeImageFile =
          formDataMap.containsKey('cheque_copy') && formDataMap['cheque_copy'] is MultipartFile;
      final hasRtgsImageFile =
          formDataMap.containsKey('rtgs_image') && formDataMap['rtgs_image'] is MultipartFile;
        final hasUpiImageFile =
          formDataMap.containsKey('upi_image') && formDataMap['upi_image'] is MultipartFile;
      if (hasSalarySlipFile) {
        formDataMap.remove('salary_slip_path');
      }
      if (hasForm16AFile) {
        formDataMap.remove('form_16a_path');
      }
      if (hasChequeImageFile) {
        formDataMap.remove('cheque_copy_name');
      }
      if (hasRtgsImageFile) {
        formDataMap.remove('rtgs_image_name');
      }
      if (hasUpiImageFile) {
        formDataMap.remove('upi_image_name');
      }
      formDataMap.remove('documents');

      // // Single form field whose value is a JSON array string, e.g. "[14,15]"
      // formDataMap['plot_ids'] = jsonEncode(request.plotIds);

      // debugPrint('📤 createBooking: formDataMap[plot_ids] ${formDataMap['plot_ids']} document files for web upload');


      // final formData = FormData.fromMap(formDataMap, ListFormat.multi);

     // Create formData
      final formData = FormData.fromMap(
        formDataMap,
        ListFormat.multi,
      );

      // Send plot_ids as indexed array
      for (int i = 0; i < request.plotIds.length; i++) {
        formData.fields.add(
          MapEntry('plot_ids[$i]', request.plotIds[i].toString()),
        );
      }

      debugPrint('📤 plot_ids=${request.plotIds}');
     
     
         // Handle documents array - add all documents with the same key "documents" to form an array
      if (kIsWeb && documentFiles != null && documentFiles.isNotEmpty) {
        debugPrint('📤 createBooking: Processing ${documentFiles.length} document files for web upload');
        // On web, use file bytes from documentFiles
        for (var fileData in documentFiles) {
          final bytes = fileData['bytes'] as List<int>?;
          final fileName = fileData['name'] as String?;
          
          debugPrint('📄 createBooking: File ${fileName}, bytes: ${bytes?.length ?? 0}');
          
          if (bytes == null || fileName == null || bytes.isEmpty) {
            debugPrint('⚠️ createBooking: Skipping file ${fileName} - missing bytes or name');
            continue;
          }
          
          final fileExtension = fileName.split('.').last.toLowerCase();
          
          // Determine content type
          String? contentType;
          if (fileExtension == 'pdf') {
            contentType = 'application/pdf';
          } else if (['jpg', 'jpeg'].contains(fileExtension)) {
            contentType = 'image/jpeg';
          } else if (fileExtension == 'png') {
            contentType = 'image/png';
          }
          
          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: contentType != null 
                ? MediaType.parse(contentType) 
                : null,
          );
          
          // Add each document file with the same key "documents" to create an array
          formData.files.add(MapEntry('documents', multipartFile));
          debugPrint('✅ createBooking: Added document file ${fileName} to form data');
        }
        debugPrint('📦 createBooking: Total files in form data: ${formData.files.length}');
      } else if (request.documents != null && request.documents!.isNotEmpty) {
        // On mobile, use file paths
        for (var documentPath in request.documents!) {
          if (documentPath.isEmpty) continue;
          
          if (kIsWeb) {
            // On web, if it's a URL, add it as a string field
            if (documentPath.startsWith('http')) {
              formData.fields.add(MapEntry('documents', documentPath));
              continue;
            }
            // Skip web file paths if no file data provided
            debugPrint('Web file upload from path not supported: $documentPath');
            continue;
          } else {
            // On mobile, use File API
            try {
              final documentFile = File(documentPath);
              if (await documentFile.exists()) {
                final fileName = documentPath.split('/').last;
                final fileExtension = fileName.split('.').last.toLowerCase();
                
                // Determine content type
                String? contentType;
                if (fileExtension == 'pdf') {
                  contentType = 'application/pdf';
                } else if (['jpg', 'jpeg'].contains(fileExtension)) {
                  contentType = 'image/jpeg';
                } else if (fileExtension == 'png') {
                  contentType = 'image/png';
                }
                
                final multipartFile = await MultipartFile.fromFile(
                  documentPath,
                  filename: fileName,
                  contentType: contentType != null 
                      ? MediaType.parse(contentType) 
                      : null,
                );
                
                // Add each document file with the same key "documents" to create an array
                formData.files.add(MapEntry('documents', multipartFile));
              }
            } catch (e) {
              // File doesn't exist or can't be accessed, skip
              debugPrint('Error adding document file: $e');
            }
          }
        }
      }

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
      // Check for 413 status code (Request Entity Too Large)
      if (e.response?.statusCode == 413) {
        throw Exception('Selected file size Too Large');
      }
      // Extract the actual error message from the API response
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create a new plot hold — POST [ApiConstants.plotHoldsCreate] with `plot_ids` array.
  /// Uses `application/json` when no document uploads; multipart when files are attached.
  Future<HoldResponseModel> createHold(
    HoldRequestModel request, {
    List<Map<String, dynamic>>? documentFiles,
  }) async {
    try {
      if (request.plotIds.isEmpty) {
        throw Exception('plot_ids is required: select at least one plot.');
      }

      if (!_createHoldNeedsMultipart(request, documentFiles)) {
        debugPrint('createHold JSON plot_ids=${request.plotIds}');
        final response = await _apiClient.post(
          ApiConstants.plotHoldsCreate,
          data: request.toJson(),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          return HoldResponseModel.fromJson(response.data);
        }
        throw Exception('Failed to create hold: ${response.statusMessage}');
      }

      debugPrint('createHold multipart plot_ids=${request.plotIds} (plot_ids as JSON string)');

      // Create FormData for multipart request
      final Map<String, dynamic> formDataMap = {...request.toFormData()};

      formDataMap.remove('documents');
      formDataMap['plot_ids'] = request.plotIds;

      final formData = FormData.fromMap(formDataMap, ListFormat.multi);
      debugPrint('createHold multipart formData=${formData}');

      // Handle documents array - add all documents with the same key "documents" to form an array
      if (kIsWeb && documentFiles != null && documentFiles.isNotEmpty) {
        debugPrint('📤 createHold: Processing ${documentFiles.length} document files for web upload');
        // On web, use file bytes from documentFiles
        for (var fileData in documentFiles) {
          final bytes = fileData['bytes'] as List<int>?;
          final fileName = fileData['name'] as String?;
          
          debugPrint('📄 createHold: File ${fileName}, bytes: ${bytes?.length ?? 0}');
          
          if (bytes == null || fileName == null || bytes.isEmpty) {
            debugPrint('⚠️ createHold: Skipping file ${fileName} - missing bytes or name');
            continue;
          }
          
          final fileExtension = fileName.split('.').last.toLowerCase();
          
          // Determine content type
          String? contentType;
          if (fileExtension == 'pdf') {
            contentType = 'application/pdf';
          } else if (['jpg', 'jpeg'].contains(fileExtension)) {
            contentType = 'image/jpeg';
          } else if (fileExtension == 'png') {
            contentType = 'image/png';
          }
          
          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: fileName,
            contentType: contentType != null 
                ? MediaType.parse(contentType) 
                : null,
          );
          
          // Add each document file with the same key "documents" to create an array
          formData.files.add(MapEntry('documents', multipartFile));
          debugPrint('✅ createHold: Added document file ${fileName} to form data');
        }
        debugPrint('📦 createHold: Total files in form data: ${formData.files.length}');
      } else if (request.documents != null && request.documents!.isNotEmpty) {
        // On mobile, use file paths
        for (var documentPath in request.documents!) {
          if (documentPath.isEmpty) continue;
          
          if (kIsWeb) {
            // On web, if it's a URL, add it as a string field
            if (documentPath.startsWith('http')) {
              formData.fields.add(MapEntry('documents', documentPath));
              continue;
            }
            // Skip web file paths if no file data provided
            debugPrint('Web file upload from path not supported: $documentPath');
            continue;
          } else {
            // On mobile, use File API
            try {
              final documentFile = File(documentPath);
              if (await documentFile.exists()) {
                final fileName = documentPath.split('/').last;
                final fileExtension = fileName.split('.').last.toLowerCase();
                
                // Determine content type
                String? contentType;
                if (fileExtension == 'pdf') {
                  contentType = 'application/pdf';
                } else if (['jpg', 'jpeg'].contains(fileExtension)) {
                  contentType = 'image/jpeg';
                } else if (fileExtension == 'png') {
                  contentType = 'image/png';
                }
                
                final multipartFile = await MultipartFile.fromFile(
                  documentPath,
                  filename: fileName,
                  contentType: contentType != null 
                      ? MediaType.parse(contentType) 
                      : null,
                );
                
                // Add each document file with the same key "documents" to create an array
                formData.files.add(MapEntry('documents', multipartFile));
              }
            } catch (e) {
              // File doesn't exist or can't be accessed, skip
              debugPrint('Error adding document file: $e');
            }
          }
        }
      }
      
      final response = await _apiClient.postMultipart(
        ApiConstants.plotHoldsCreate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return HoldResponseModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create hold: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Check for 413 status code (Request Entity Too Large)
      if (e.response?.statusCode == 413) {
        throw Exception('Selected file size Too Large');
      }
      // Extract the actual error message from the API response
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
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
      throw Exception(_isNetworkFailure(e)
          ? _noInternetMessage
          : 'API Error: ${e.message}');
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
      throw Exception(_isNetworkFailure(e)
          ? _noInternetMessage
          : 'API Error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update an existing plot hold
  Future<HoldListModel> updateHold(int holdId, Map<String, dynamic> updateData) async {
    try {
      // API endpoint: /api/v1/plot-holds/{id}
      final endpoint = '${ApiConstants.plotHolds}$holdId/';
      final response = await _apiClient.patch(
        endpoint,
        data: updateData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return HoldListModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update hold: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Extract the actual error message from the API response
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update an existing plot booking with multipart/form-data
  Future<BookingListModel> updateBooking(int bookingId, Map<String, dynamic> updateData) async {
    try {
      // API endpoint: /api/v1/plot-bookings/{id}/
      final endpoint = '${ApiConstants.plotBookings}$bookingId/';
      
      // Create FormData for multipart request
      final Map<String, dynamic> formDataMap = {...updateData};
      
      // Add files if they exist and are valid
      if (updateData['salary_slip_path'] != null && updateData['salary_slip_path'].toString().isNotEmpty) {
        final salarySlipPath = updateData['salary_slip_path'].toString();
        // Remove the path from formDataMap since we'll add it as MultipartFile
        formDataMap.remove('salary_slip_path');
        
        // On web, file paths are just filenames, not real paths
        if (kIsWeb) {
          // On web, if it's a URL, just pass it as a string
          if (salarySlipPath.startsWith('http')) {
            formDataMap['salary_slip_path'] = salarySlipPath;
          }
          // Otherwise, skip - web files need to be handled with file bytes
        } else {
          // On mobile, check if it's a file path (not a URL)
          if (!salarySlipPath.startsWith('http')) {
            try {
              final salarySlipFile = File(salarySlipPath);
              if (await salarySlipFile.exists()) {
                formDataMap['salary_slip'] = await MultipartFile.fromFile(
                  salarySlipPath,
                  filename: 'salary_slip.pdf',
                );
              }
            } catch (e) {
              // File doesn't exist or can't be accessed, skip
            }
          }
        }
      }
      
      if (updateData['form_16a_path'] != null && updateData['form_16a_path'].toString().isNotEmpty) {
        final form16APath = updateData['form_16a_path'].toString();
        // Remove the path from formDataMap since we'll add it as MultipartFile
        formDataMap.remove('form_16a_path');
        
        // On web, file paths are just filenames, not real paths
        if (kIsWeb) {
          // On web, if it's a URL, just pass it as a string
          if (form16APath.startsWith('http')) {
            formDataMap['form_16a_path'] = form16APath;
          }
          // Otherwise, skip - web files need to be handled with file bytes
        } else {
          // On mobile, check if it's a file path (not a URL)
          if (!form16APath.startsWith('http')) {
            try {
              final form16AFile = File(form16APath);
              if (await form16AFile.exists()) {
                formDataMap['form_16a'] = await MultipartFile.fromFile(
                  form16APath,
                  filename: 'form_16a.pdf',
                );
              }
            } catch (e) {
              // File doesn't exist or can't be accessed, skip
            }
          }
        }
      }

      if (updateData['cheque_copy_bytes'] != null) {
        final chequeBytesRaw = updateData['cheque_copy_bytes'];
        final chequeCopyName = updateData['cheque_copy_name']?.toString() ?? 'cheque_image.jpg';

        formDataMap.remove('cheque_copy_bytes');
        formDataMap.remove('cheque_copy_name');

        List<int>? chequeBytes;
        if (chequeBytesRaw is List<int>) {
          chequeBytes = chequeBytesRaw;
        } else if (chequeBytesRaw is List) {
          chequeBytes = chequeBytesRaw.map((e) => e as int).toList();
        }

        if (chequeBytes != null && chequeBytes.isNotEmpty) {
          final extension = chequeCopyName.split('.').last.toLowerCase();
          String? contentType;
          if (extension == 'jpg' || extension == 'jpeg') {
            contentType = 'image/jpeg';
          } else if (extension == 'png') {
            contentType = 'image/png';
          }

          formDataMap['cheque_copy'] = MultipartFile.fromBytes(
            chequeBytes,
            filename: chequeCopyName,
            contentType: contentType != null ? MediaType.parse(contentType) : null,
          );
        }
      }

      if (updateData['rtgs_image_bytes'] != null) {
        final rtgsBytesRaw = updateData['rtgs_image_bytes'];
        final rtgsImageName = updateData['rtgs_image_name']?.toString() ?? 'rtgs_image.jpg';

        formDataMap.remove('rtgs_image_bytes');
        formDataMap.remove('rtgs_image_name');

        List<int>? rtgsBytes;
        if (rtgsBytesRaw is List<int>) {
          rtgsBytes = rtgsBytesRaw;
        } else if (rtgsBytesRaw is List) {
          rtgsBytes = rtgsBytesRaw.map((e) => e as int).toList();
        }

        if (rtgsBytes != null && rtgsBytes.isNotEmpty) {
          final extension = rtgsImageName.split('.').last.toLowerCase();
          String? contentType;
          if (extension == 'jpg' || extension == 'jpeg') {
            contentType = 'image/jpeg';
          } else if (extension == 'png') {
            contentType = 'image/png';
          }

          formDataMap['rtgs_image'] = MultipartFile.fromBytes(
            rtgsBytes,
            filename: rtgsImageName,
            contentType: contentType != null ? MediaType.parse(contentType) : null,
          );
        }
      }

      if (updateData['upi_image_bytes'] != null) {
        final upiBytesRaw = updateData['upi_image_bytes'];
        final upiImageName = updateData['upi_image_name']?.toString() ?? 'upi_image.jpg';

        formDataMap.remove('upi_image_bytes');
        formDataMap.remove('upi_image_name');

        List<int>? upiBytes;
        if (upiBytesRaw is List<int>) {
          upiBytes = upiBytesRaw;
        } else if (upiBytesRaw is List) {
          upiBytes = upiBytesRaw.map((e) => e as int).toList();
        }

        if (upiBytes != null && upiBytes.isNotEmpty) {
          final extension = upiImageName.split('.').last.toLowerCase();
          String? contentType;
          if (extension == 'jpg' || extension == 'jpeg') {
            contentType = 'image/jpeg';
          } else if (extension == 'png') {
            contentType = 'image/png';
          }

          formDataMap['upi_image'] = MultipartFile.fromBytes(
            upiBytes,
            filename: upiImageName,
            contentType: contentType != null ? MediaType.parse(contentType) : null,
          );
        }
      }
      
      final formData = FormData.fromMap(formDataMap);

      // Use patch with FormData (Dio supports multipart with PATCH)
      final response = await _apiClient.dio.patch(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookingListModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update booking: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Check for 413 status code (Request Entity Too Large)
      if (e.response?.statusCode == 413) {
        throw Exception('Selected file size Too Large');
      }
      // Extract the actual error message from the API response
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Add a document to a hold
  Future<Map<String, dynamic>> addHoldDocument({
    required int holdId,
    required String filePath,
    required String filetype,
    String? description,
    XFile? xFile,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final formData = FormData();
      
      // Add hold ID
      formData.fields.add(MapEntry('hold', holdId.toString()));
      
      // Add filetype
      formData.fields.add(MapEntry('filetype', filetype));
      
      // Add description if provided
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }
      
      // Add file
      if (kIsWeb) {
        // On web, use file bytes (from XFile or file_picker), otherwise try URL
        List<int>? bytes;
        String? finalFileName;
        
        if (xFile != null) {
          try {
            bytes = await xFile.readAsBytes();
            finalFileName = xFile.name.isNotEmpty ? xFile.name : filePath.split('/').last;
          } catch (e) {
            throw Exception('Error reading file bytes: $e');
          }
        } else if (fileBytes != null && fileBytes.isNotEmpty) {
          bytes = fileBytes;
          finalFileName = fileName ?? filePath.split('/').last;
        } else if (filePath.startsWith('http')) {
          // If it's a URL, add it as a string field
          formData.fields.add(MapEntry('document', filePath));
          bytes = null; // Skip file processing
        } else {
          throw Exception('Web file upload requires XFile, file bytes, or URL. Please try selecting the file again.');
        }
        
        if (bytes != null && finalFileName != null) {
          final fileExtension = finalFileName.split('.').last.toLowerCase();
          
          // Determine content type
          String? contentType;
          if (fileExtension == 'pdf') {
            contentType = 'application/pdf';
          } else if (['jpg', 'jpeg'].contains(fileExtension)) {
            contentType = 'image/jpeg';
          } else if (fileExtension == 'png') {
            contentType = 'image/png';
          }
          
          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: finalFileName,
            contentType: contentType != null 
                ? MediaType.parse(contentType) 
                : null,
          );
          
          formData.files.add(MapEntry('document', multipartFile));
        }
      } else {
        // On mobile, use File API
        try {
          final documentFile = File(filePath);
          if (await documentFile.exists()) {
            final fileName = filePath.split('/').last;
            final fileExtension = fileName.split('.').last.toLowerCase();
            
            // Determine content type
            String? contentType;
            if (fileExtension == 'pdf') {
              contentType = 'application/pdf';
            } else if (['jpg', 'jpeg'].contains(fileExtension)) {
              contentType = 'image/jpeg';
            } else if (fileExtension == 'png') {
              contentType = 'image/png';
            }
            
            final multipartFile = await MultipartFile.fromFile(
              filePath,
              filename: fileName,
              contentType: contentType != null 
                  ? MediaType.parse(contentType) 
                  : null,
            );
            
            formData.files.add(MapEntry('document', multipartFile));
          } else {
            throw Exception('File does not exist');
          }
        } catch (e) {
          throw Exception('Error adding file: $e');
        }
      }
      
      final response = await _apiClient.postMultipart(
        ApiConstants.plotHoldDocuments,
        data: formData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic> 
            ? response.data as Map<String, dynamic>
            : {'id': response.data};
      } else {
        throw Exception('Failed to add hold document: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception('Selected file size Too Large');
      }
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete a hold document
  Future<void> deleteHoldDocument(int documentId) async {
    try {
      final endpoint = '${ApiConstants.plotHoldDocuments}$documentId/';
      final response = await _apiClient.delete(endpoint);
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete hold document: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Add a document to a booking
  Future<Map<String, dynamic>> addBookingDocument({
    required int bookingId,
    required String filePath,
    required String filetype,
    String? description,
    XFile? xFile,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      final formData = FormData();
      
      // Add booking ID
      formData.fields.add(MapEntry('booking', bookingId.toString()));
      
      // Add filetype
      formData.fields.add(MapEntry('filetype', filetype));
      
      // Add description if provided
      if (description != null && description.isNotEmpty) {
        formData.fields.add(MapEntry('description', description));
      }
      
      // Add file
      if (kIsWeb) {
        // On web, use file bytes (from XFile or file_picker)
        List<int>? bytes;
        String? finalFileName;
        
        if (xFile != null) {
          try {
            bytes = await xFile.readAsBytes();
            finalFileName = xFile.name.isNotEmpty ? xFile.name : filePath.split('/').last;
          } catch (e) {
            throw Exception('Error reading file bytes: $e');
          }
        } else if (fileBytes != null) {
          bytes = fileBytes;
          finalFileName = fileName ?? filePath.split('/').last;
        } else if (filePath.startsWith('http')) {
          // If it's a URL, add it as a string field
          formData.fields.add(MapEntry('document', filePath));
          bytes = null; // Skip file processing
        } else {
          throw Exception('Web file upload requires XFile, file bytes, or URL');
        }
        
        if (bytes != null && finalFileName != null) {
          final fileExtension = finalFileName.split('.').last.toLowerCase();
          
          // Determine content type
          String? contentType;
          if (fileExtension == 'pdf') {
            contentType = 'application/pdf';
          } else if (['jpg', 'jpeg'].contains(fileExtension)) {
            contentType = 'image/jpeg';
          } else if (fileExtension == 'png') {
            contentType = 'image/png';
          }
          
          final multipartFile = MultipartFile.fromBytes(
            bytes,
            filename: finalFileName,
            contentType: contentType != null 
                ? MediaType.parse(contentType) 
                : null,
          );
          
          formData.files.add(MapEntry('document', multipartFile));
        }
      } else {
        // On mobile, use File API
        try {
          final documentFile = File(filePath);
          if (await documentFile.exists()) {
            final fileName = filePath.split('/').last;
            final fileExtension = fileName.split('.').last.toLowerCase();
            
            // Determine content type
            String? contentType;
            if (fileExtension == 'pdf') {
              contentType = 'application/pdf';
            } else if (['jpg', 'jpeg'].contains(fileExtension)) {
              contentType = 'image/jpeg';
            } else if (fileExtension == 'png') {
              contentType = 'image/png';
            }
            
            final multipartFile = await MultipartFile.fromFile(
              filePath,
              filename: fileName,
              contentType: contentType != null 
                  ? MediaType.parse(contentType) 
                  : null,
            );
            
            formData.files.add(MapEntry('document', multipartFile));
          } else {
            throw Exception('File does not exist');
          }
        } catch (e) {
          throw Exception('Error adding file: $e');
        }
      }
      
      final response = await _apiClient.postMultipart(
        ApiConstants.plotBookingDocuments,
        data: formData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic> 
            ? response.data as Map<String, dynamic>
            : {'id': response.data};
      } else {
        throw Exception('Failed to add booking document: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception('Selected file size Too Large');
      }
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete a booking document
  Future<void> deleteBookingDocument(int documentId) async {
    try {
      final endpoint = '${ApiConstants.plotBookingDocuments}$documentId/';
      final response = await _apiClient.delete(endpoint);
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete booking document: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
