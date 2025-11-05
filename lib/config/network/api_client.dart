import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'dart:developer' as dev;


class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _init();
  }
  
  // Expose secure storage for use in repositories
  FlutterSecureStorage get secureStorage => _secureStorage;

  void _init() {
    String baseUrl;
    try {
      baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.example.com';
      print('API Client: Using base URL: $baseUrl');
    } catch (e) {
      print('API Client: Error getting BASE_URL from environment: $e');
      // Fallback URLs based on environment
      final env = dotenv.env['ENVIRONMENT'] ?? 'dev';
      baseUrl = env == 'prod' 
        ? 'https://pigeonm.com/api' 
        : 'https://daf8f7648993.ngrok-free.app/api/v1/';
      print('API Client: Using fallback base URL: $baseUrl');
    }
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add logging interceptor
    _dio.interceptors.add(TalkerDioLogger());
    
    // Add interceptor to include access token in requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('Making API request to: ${options.uri}');
        try {
          // Get access token from secure storage
          final accessToken = await _secureStorage.read(key: 'access_token');
          debugPrint('Access token from secure storage: $accessToken');
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
            print('Added Authorization header to request');
          } else {
            print('No access token found in secure storage');
          }
          print('Request headers: ${options.headers}');
        } catch (e) {
          print('Error reading access token: $e');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) { 
        dev.log('API URL: $baseUrl');
        dev.log('API response status: ${response.statusCode}');
        dev.log('API response data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('API error: ${e.message}');
        print('Error URL: ${e.requestOptions.uri}');
        if (e.response != null) {
          print('Error status: ${e.response?.statusCode}');
          print('Error data: ${e.response?.data}');
        }
        
        // Handle specific error cases
        if (e.error?.toString().contains('Failed host lookup') ?? false) {
          print('Network error: Please check your internet connection');
        }
        
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  // Generic GET request
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      print('Making GET request to: $endpoint');
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error in GET request: $e');
      rethrow;
    }
  }

  // Generic POST request
  Future<Response> post(String endpoint, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      print('Making POST request to: $endpoint');
      return await _dio.post(endpoint, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error in POST request: $e');
      rethrow;
    }
  }

  // Multipart POST request for file uploads
  Future<Response> postMultipart(String endpoint, {FormData? data, Map<String, dynamic>? queryParameters}) async {
    try {
      print('Making multipart POST request to: $endpoint');
      return await _dio.post(
        endpoint, 
        data: data, 
        queryParameters: queryParameters,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error in multipart POST request: $e');
      rethrow;
    }
  }

  // Generic PUT request
  Future<Response> put(String endpoint, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      print('Making PUT request to: $endpoint');
      return await _dio.put(endpoint, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error in PUT request: $e');
      rethrow;
    }
  }

  // Generic PATCH request
  Future<Response> patch(String endpoint, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      print('Making PATCH request to: $endpoint');
      return await _dio.patch(endpoint, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error in PATCH request: $e');
      rethrow;
    }
  }

  // Generic DELETE request
  Future<Response> delete(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      print('Making DELETE request to: $endpoint');
      return await _dio.delete(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      print('Unexpected error in DELETE request: $e');
      rethrow;
    }
  }

  void _handleError(DioException error) {
    print('API Error: ${error.message}');
    print('Error URL: ${error.requestOptions.uri}');
    
    if (error.response != null) {
      print('Error Status: ${error.response?.statusCode}');
      print('Error Data: ${error.response?.data}');
    }
    
    // Provide user-friendly error messages
    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      print('Network timeout error. Please check your internet connection.');
    } else if (error.type == DioExceptionType.badCertificate) {
      print('SSL certificate error. Please contact support.');
    } else if (error.type == DioExceptionType.badResponse) {
      print('Server error. Please try again later.');
    } else if (error.type == DioExceptionType.cancel) {
      print('Request was cancelled.');
    } else if (error.type == DioExceptionType.connectionError) {
      print('Connection error. Please check your internet connection.');
    }
  }
}