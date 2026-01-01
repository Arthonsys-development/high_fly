import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:highfly/config/network/tenant_keys.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:highfly/config/routes.dart';
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

  // Force logout user when 401 is received
  Future<void> _forceLogout() async {
    try {
      debugPrint('API Client: 401 Unauthorized - Forcing logout');
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      debugPrint('API Client: Signed out from Firebase');
      
      // Clear all secure storage
      await _secureStorage.deleteAll();
      debugPrint('API Client: Cleared secure storage');
      
      // Navigate to sign in screen using router
      // Use a post-frame callback to ensure navigation happens after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          router.go(Routes.signIn);
          debugPrint('API Client: Navigated to sign in screen');
        } catch (e) {
          debugPrint('API Client: Error navigating to sign in: $e');
        }
      });
    } catch (e) {
      debugPrint('API Client: Error during force logout: $e');
    }
  }

  void _init() {
    String baseUrl;
    try {
      baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.example.com';
      debugPrint('API Client: Using base URL: $baseUrl');
    } catch (e) {
      debugPrint('API Client: Error getting BASE_URL from environment: $e');
      // Fallback URLs based on environment
      final env = dotenv.env['ENVIRONMENT'] ?? 'dev';
      baseUrl = env == 'prod' 
        ? 'https://pigeonm.com/api' 
        : 'https://daf8f7648993.ngrok-free.app/api/v1/';
      debugPrint('API Client: Using fallback base URL: $baseUrl');
    }
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Tenant-API-Key': TenantApiKeyConfig.activeTenantApiKey,
      },
      // Web-specific configuration
      followRedirects: true,
    ));
    
    // Configure for web platform
    if (kIsWeb) {
      // For web, Dio automatically uses XMLHttpRequest
      // We can add additional web-specific configurations here if needed
      debugPrint('API Client: Running on web platform - CORS must be enabled on server');
    }

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
            debugPrint('Added Authorization header to request');
          } else {
            debugPrint('No access token found in secure storage');
          }
          debugPrint('Request headers: ${options.headers}');
        } catch (e) {
          debugPrint('Error reading access token: $e');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) { 
        dev.log('API URL: $baseUrl');
        dev.log('API response status: ${response.statusCode}');
        dev.log('API response data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        debugPrint('API error: ${e.message}');
        debugPrint('Error URL: ${e.requestOptions.uri}');
        
        // Detect CORS errors on web
        if (kIsWeb) {
          final errorMessage = e.message?.toLowerCase() ?? '';
          final errorString = e.error?.toString().toLowerCase() ?? '';
          
          if (errorMessage.contains('xmlhttprequest') || 
              errorMessage.contains('cors') ||
              errorString.contains('xmlhttprequest') ||
              errorString.contains('cors') ||
              e.type == DioExceptionType.connectionError) {
            debugPrint('⚠️ CORS Error Detected on Web Platform');
            debugPrint('The server at ${e.requestOptions.uri} needs to allow CORS requests.');
            debugPrint('Required CORS headers:');
            debugPrint('  - Access-Control-Allow-Origin: * (or your domain)');
            debugPrint('  - Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS');
            debugPrint('  - Access-Control-Allow-Headers: Content-Type, Authorization, X-Tenant-API-Key');
            debugPrint('  - Access-Control-Allow-Credentials: true (if using credentials)');
            
            // Create a more helpful error message
            final corsError = DioException(
              requestOptions: e.requestOptions,
              type: DioExceptionType.connectionError,
              error: 'CORS Error: The server at ${e.requestOptions.uri.host} is not configured to allow requests from this origin. '
                     'Please configure CORS headers on the server or contact your backend team.',
              message: 'CORS policy blocked the request. Server must allow cross-origin requests.',
            );
            return handler.next(corsError);
          }
        }
        
        if (e.response != null) {
          debugPrint('Error status: ${e.response?.statusCode}');
          debugPrint('Error data: ${e.response?.data}');
          
          // Handle 401 Unauthorized - Force logout
          if (e.response?.statusCode == 401) {
            debugPrint('API Client: Received 401 Unauthorized - Forcing logout');
            await _forceLogout();
            // Continue with the error so the caller can handle it if needed
            return handler.next(e);
          }
        }
        
        // Handle specific error cases
        if (e.error?.toString().contains('Failed host lookup') ?? false) {
          debugPrint('Network error: Please check your internet connection');
        }
        
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  // Generic GET request
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('Making GET request to: $endpoint');
      return await _dio.get(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in GET request: $e');
      rethrow;
    }
  }

  // Generic POST request
  Future<Response> post(String endpoint, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('Making POST request to: $endpoint');
      return await _dio.post(endpoint, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in POST request: $e');
      rethrow;
    }
  }

  // Multipart POST request for file uploads
  Future<Response> postMultipart(String endpoint, {FormData? data, Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('Making multipart POST request to: $endpoint');
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
      debugPrint('Unexpected error in multipart POST request: $e');
      rethrow;
    }
  }

  // Generic PUT request
  Future<Response> put(String endpoint, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('Making PUT request to: $endpoint');
      return await _dio.put(endpoint, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in PUT request: $e');
      rethrow;
    }
  }

  // Generic PATCH request
  Future<Response> patch(String endpoint, {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('Making PATCH request to: $endpoint');
      return await _dio.patch(endpoint, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in PATCH request: $e');
      rethrow;
    }
  }

  // Generic DELETE request
  Future<Response> delete(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      debugPrint('Making DELETE request to: $endpoint');
      return await _dio.delete(endpoint, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in DELETE request: $e');
      rethrow;
    }
  }

  void _handleError(DioException error) {
    debugPrint('API Error: ${error.message}');
    debugPrint('Error URL: ${error.requestOptions.uri}');
    
    if (error.response != null) {
      debugPrint('Error Status: ${error.response?.statusCode}');
      debugPrint('Error Data: ${error.response?.data}');
    }
    
    // Provide user-friendly error messages
    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      debugPrint('Network timeout error. Please check your internet connection.');
    } else if (error.type == DioExceptionType.badCertificate) {
      debugPrint('SSL certificate error. Please contact support.');
    } else if (error.type == DioExceptionType.badResponse) {
      debugPrint('Server error. Please try again later.');
    } else if (error.type == DioExceptionType.cancel) {
      debugPrint('Request was cancelled.');
    } else if (error.type == DioExceptionType.connectionError) {
      if (kIsWeb && error.message?.contains('CORS') == true) {
        debugPrint('CORS Error: The server is not configured to allow cross-origin requests.');
        debugPrint('This is a server-side configuration issue. The backend team needs to add CORS headers.');
      } else {
        debugPrint('Connection error. Please check your internet connection.');
      }
    }
  }
}