import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:http_parser/http_parser.dart';

class DocumentRepository {
  final ApiClient _apiClient = ApiClient();

  /// Upload a document (PDF, image, etc.)
  Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String fileName,
    String? documentType,
    Map<String, String>? additionalFields,
  }) async {
    try {
      debugPrint('📄 DocumentRepository: Uploading document...');
      
      // Determine content type based on file extension
      String contentType = 'application/octet-stream';
      if (fileName.toLowerCase().endsWith('.pdf')) {
        contentType = 'application/pdf';
      } else if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      }

      // Create multipart file with proper content type
      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );

      // Prepare form data
      final formData = FormData.fromMap({
        'file': multipartFile,
        if (documentType != null) 'document_type': documentType,
        if (additionalFields != null) ...additionalFields,
      });

      // Upload document
      final response = await _apiClient.post(
        ApiConstants.documentUpload,
        data: formData,
      );

      debugPrint('✅ DocumentRepository: Document uploaded successfully');
      debugPrint('📊 DocumentRepository: Response data: ${response.data}');

      // Return response data
      return {
        'success': true,
        'data': response.data,
        'message': 'Document uploaded successfully',
      };
    } on DioException catch (e) {
      debugPrint('❌ DocumentRepository: Error uploading document - ${e.message}');
      debugPrint('📊 DocumentRepository: Error response: ${e.response?.data}');
      
      return {
        'success': false,
        'error': e.message,
        'message': 'Failed to upload document: ${e.message}',
      };
    } catch (e) {
      debugPrint('❌ DocumentRepository: Unexpected error - $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to upload document: $e',
      };
    }
  }
}