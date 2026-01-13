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
  Future<BookingResponseModel> createBooking(BookingRequestModel request) async {
    try {
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
      
      // Create FormData manually to ensure proper array handling for documents
      final formData = FormData();
      
      // Track which file keys we have so we can skip corresponding path fields
      final hasSalarySlipFile = formDataMap.containsKey('salary_slip') && formDataMap['salary_slip'] is MultipartFile;
      final hasForm16AFile = formDataMap.containsKey('form_16a') && formDataMap['form_16a'] is MultipartFile;
      
      // Add all form fields from formDataMap
      for (var entry in formDataMap.entries) {
        // Skip documents key as we'll add files separately
        if (entry.key == 'documents') continue;
        
        // Skip path fields if we have the actual file
        if (entry.key == 'salary_slip_path' && hasSalarySlipFile) {
          continue;
        }
        if (entry.key == 'form_16a_path' && hasForm16AFile) {
          continue;
        }
        
        // Handle MultipartFile entries (salary_slip, form_16a) - add as files
        if (entry.value is MultipartFile) {
          formData.files.add(MapEntry(entry.key, entry.value as MultipartFile));
        } else {
          formData.fields.add(MapEntry(entry.key, entry.value.toString()));
        }
      }
      
      // Handle documents array - add all documents with the same key "documents" to form an array
      if (request.documents != null && request.documents!.isNotEmpty) {
        for (var documentPath in request.documents!) {
          if (documentPath.isEmpty) continue;
          
          if (kIsWeb) {
            // On web, if it's a URL, add it as a string field
            if (documentPath.startsWith('http')) {
              formData.fields.add(MapEntry('documents', documentPath));
              continue;
            }
            // For web, files from image_picker/file_picker need special handling
            // Skip for now as web file handling requires bytes
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

  /// Create a new plot hold with multipart/form-data
  Future<HoldResponseModel> createHold(HoldRequestModel request) async {
    try {
      // Create FormData for multipart request
      final Map<String, dynamic> formDataMap = {...request.toJson()};
      
      // Create FormData manually to ensure proper array handling for documents
      final formData = FormData();
      
      // Add all form fields from formDataMap
      for (var entry in formDataMap.entries) {
        // Skip documents key as we'll add files separately
        if (entry.key == 'documents') continue;
        
        formData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
      
      // Handle documents array - add all documents with the same key "documents" to form an array
      if (request.documents != null && request.documents!.isNotEmpty) {
        for (var documentPath in request.documents!) {
          if (documentPath.isEmpty) continue;
          
          if (kIsWeb) {
            // On web, if it's a URL, add it as a string field
            if (documentPath.startsWith('http')) {
              formData.fields.add(MapEntry('documents', documentPath));
              continue;
            }
            // For web, files from image_picker/file_picker need special handling
            // Skip for now as web file handling requires bytes
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
        ApiConstants.plotHolds,
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
        // On web, use XFile bytes if provided, otherwise try URL
        if (xFile != null) {
          try {
            final bytes = await xFile.readAsBytes();
            final fileName = xFile.name.isNotEmpty ? xFile.name : filePath.split('/').last;
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
            
            formData.files.add(MapEntry('document', multipartFile));
          } catch (e) {
            throw Exception('Error reading file bytes: $e');
          }
        } else if (filePath.startsWith('http')) {
          // If it's a URL, add it as a string field
          formData.fields.add(MapEntry('document', filePath));
        } else {
          throw Exception('Web file upload requires XFile object or URL');
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
