import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:highfly/data/models/request_models/auth_request_model.dart';
import 'package:highfly/data/models/request_models/visit_request_model.dart';
import 'package:highfly/data/models/request_models/notification_register_request_model.dart';
import 'package:highfly/data/models/response_model/project_response_model.dart';
import 'package:highfly/data/models/response_model/user_response_model.dart';
import 'package:highfly/data/models/response_model/visit_response_model.dart';
import 'package:highfly/data/models/project_model.dart' as local_model;
import 'package:dio/dio.dart';

class AuthApiRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.verifyPhone,
        data: {
          'phone_number': phoneNumber,
        },
      );

      return {
        'success': true,
        'data': response.data,
        'message': response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Phone number verification successful',
      };
    } on DioException catch (e) {
      debugPrint('DioException in verifyPhoneNumber: ${e.message}');
      String errorMessage = 'Unable to verify phone number';

      if (e.response != null) {
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message']?.toString() ??
              responseData['detail']?.toString() ??
              errorMessage;
        } else if (responseData is String && responseData.isNotEmpty) {
          errorMessage = responseData;
        }
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }

      return {
        'success': false,
        'error': e.toString(),
        'message': errorMessage,
      };
    } catch (e) {
      debugPrint('Exception in verifyPhoneNumber: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Unable to verify phone number',
      };
    }
  }

  // Register user
  Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      final formData = request.toFormData();
      final response = await _apiClient.post(
        ApiConstants.register,
        data: formData,
      );
      
      return {
        'success': true,
        'data': response.data,
        'message': 'Registration successful',
      };
    } on DioException catch (e) {
      debugPrint('DioException in register: ${e.message}');
      String errorMessage = 'Registration failed';
      
      // Extract error message from response
      if (e.response != null) {
        debugPrint('Error response data: ${e.response?.data}');
        debugPrint('Error status code: ${e.response?.statusCode}');
        
        final responseData = e.response?.data;
        if (responseData != null) {
          // Try to extract error message from different response formats
          if (responseData is Map<String, dynamic>) {
            // Common error response formats
            errorMessage = responseData['error']?.toString() ?? 
                          responseData['message']?.toString() ?? 
                          responseData['detail']?.toString() ?? 
                          responseData['non_field_errors']?.toString() ?? 
                          errorMessage;
            
            // Handle field-specific errors
            if (errorMessage == 'Registration failed' && responseData.isNotEmpty) {
              // Collect all error messages (without field name prefix)
              final errorMessages = <String>[];
              responseData.forEach((key, value) {
                if (value is List && value.isNotEmpty) {
                  errorMessages.add(value.join(", "));
                } else if (value is String && value.isNotEmpty) {
                  errorMessages.add(value);
                }
              });
              if (errorMessages.isNotEmpty) {
                errorMessage = errorMessages.join('\n');
              }
            }
          } else if (responseData is String) {
            errorMessage = responseData;
          } else if (responseData is List && responseData.isNotEmpty) {
            errorMessage = responseData.join(', ');
          }
        }
      } else {
        // Network or other errors
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection error. Please check your internet connection.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMessage = e.message!;
        }
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': errorMessage,
      };
    } catch (e) {
      debugPrint('Exception in register: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Verify login token
  Future<Map<String, dynamic>> verifyToken(LoginTokenRequest request) async {
    try {
      debugPrint('Sending verifyToken request with data: ${request.toJson()}');
      final response = await _apiClient.post(
        ApiConstants.loginToken,
        data: request.toJson(),
      );
      debugPrint('Received verifyToken response: ${response.data}');
      
      // Save access token and user data to secure storage if they exist in the response
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        
        // Save access token if it exists
        if (responseData.containsKey('access_token') && responseData['access_token'] != null) {
          final accessToken = responseData['access_token'];
          await _apiClient.secureStorage.write(
            key: 'access_token',
            value: accessToken,
          );
          debugPrint('Access token saved to secure storage');
        } else {
          debugPrint('No access token found in response data');
        }
        
        // Save user data if it exists
        if (responseData.containsKey('user') && responseData['user'] != null) {
          final user = responseData['user'];
          if (user is Map<String, dynamic>) {
            // Convert user data to JSON string and save to secure storage
            final jsonString = jsonEncode(user);
            await _apiClient.secureStorage.write(
              key: 'user_data',
              value: jsonString,
            );
            debugPrint('User data saved to secure storage: $jsonString');
          }
        } else {
          debugPrint('No user data found in response data');
        }
      } else {
        debugPrint('Response data is not a Map: ${response.data.runtimeType}');
      }
      
      return {
        'success': true,
        'data': response.data,
        'message': 'Token verification successful',
      };
    } on DioException catch (e) {
      debugPrint('DioException in verifyToken: ${e.message}');
      String errorMessage = 'Token verification failed';
      
      // Extract error message from response
      if (e.response != null) {
        debugPrint('Error response data: ${e.response?.data}');
        debugPrint('Error status code: ${e.response?.statusCode}');
        
        final responseData = e.response?.data;
        if (responseData != null) {
          // Try to extract error message from different response formats
          if (responseData is Map<String, dynamic>) {
            // Common error response formats
            errorMessage = responseData['error']?.toString() ?? 
                          responseData['message']?.toString() ?? 
                          responseData['detail']?.toString() ?? 
                          responseData['non_field_errors']?.toString() ?? 
                          errorMessage;
            
            // Handle field-specific errors
            if (errorMessage == 'Token verification failed' && responseData.isNotEmpty) {
              // Collect all error messages (without field name prefix)
              final errorMessages = <String>[];
              responseData.forEach((key, value) {
                if (value is List && value.isNotEmpty) {
                  errorMessages.add(value.join(", "));
                } else if (value is String && value.isNotEmpty) {
                  errorMessages.add(value);
                }
              });
              if (errorMessages.isNotEmpty) {
                errorMessage = errorMessages.join('\n');
              }
            }
          } else if (responseData is String) {
            errorMessage = responseData;
          } else if (responseData is List && responseData.isNotEmpty) {
            errorMessage = responseData.join(', ');
          }
        }
      } else {
        // Network or other errors
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection error. Please check your internet connection.';
        } else if (e.message != null && e.message!.isNotEmpty) {
          errorMessage = e.message!;
        }
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': errorMessage,
      };
    } catch (e) {
      debugPrint('Exception in verifyToken: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Token verification failed: ${e.toString()}',
      };
    }
  }

  // Get user data from secure storage
  Future<User?> getUserFromSecureStorage() async {
    try {
      final userDataString = await _apiClient.secureStorage.read(key: 'user_data');
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        if (userData is Map<String, dynamic>) {
          return User.fromJson(userData);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user from secure storage: $e');
      return null;
    }
  }

  // Get all projects
  Future<Map<String, dynamic>> getProjects() async {
    print('Fetching all projects from API...');
    try {
      final response = await _apiClient.get(ApiConstants.projects);
    //  log('Projects API response status: ${response.statusCode}');
      print('Projects API response data type: ${response.data.runtimeType}');
      print('Projects API response data: $response.data');
      
      // Parse projects from response
      List<Project> projects = [];
      
      // Handle different response formats
      if (response.data is List) {
        print('Parsing projects from list format, count: ${response.data.length}');
        projects = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => Project.fromJson(item))
            .toList();
      } else if (response.data is Map) {
        // Check if it's a paginated response
        if (response.data['results'] is List) {
          print('Parsing projects from paginated format');
          projects = (response.data['results'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item))
              .toList();
        } else if (response.data['data'] is List) {
          print('Parsing projects from data field format');
          projects = (response.data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item))
              .toList();
        } else if (response.data['projects'] is List) {
          print('Parsing projects from projects field format');
          projects = (response.data['projects'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item))
              .toList();
        } else {
          // Try to parse the entire map as a single project
          print('Attempting to parse response as single project object');
          try {
            final project = Project.fromJson(response.data);
            projects = [project];
          } catch (e) {
            print('Failed to parse response as single project: $e');
          }
        }
      } else {
        print('Unexpected response format: ${response.data.runtimeType}');
      }
      
      print('Successfully parsed ${projects.length} projects');
      return {
        'success': true,
        'data': projects,
        'message': 'Projects fetched successfully',
      };
    } catch (e, stackTrace) {
      print('Error fetching projects: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to fetch projects',
      };
    }
  }

  // Get active projects
  Future<Map<String, dynamic>> getActiveProjects() async {
    print('Fetching active projects from API...');
    try {
      final response = await _apiClient.get('${ApiConstants.projects}?status=active');
      print('Active projects API response status: ${response.statusCode}');
      print('Active projects API response data type: ${response.data.runtimeType}');
      print('Active projects API response data: $response.data');
      
      // Parse projects from response
      List<Project> projects = [];
      
      // Handle different response formats
      if (response.data is List) {
        print('Parsing active projects from list format, count: ${response.data.length}');
        projects = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => Project.fromJson(item))
            .toList();
      } else if (response.data is Map) {
        // Check if it's a paginated response
        if (response.data['results'] is List) {
          print('Parsing active projects from paginated format');
          projects = (response.data['results'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item))
              .toList();
        } else if (response.data['data'] is List) {
          print('Parsing active projects from data field format');
          projects = (response.data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item))
              .toList();
        } else if (response.data['projects'] is List) {
          print('Parsing active projects from projects field format');
          projects = (response.data['projects'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item))
              .toList();
        } else {
          // Try to parse the entire map as a single project
          print('Attempting to parse response as single project object');
          try {
            final project = Project.fromJson(response.data);
            projects = [project];
          } catch (e) {
            print('Failed to parse response as single project: $e');
          }
        }
      } else {
        print('Unexpected response format for active projects: ${response.data.runtimeType}');
      }
      
      print('Successfully parsed ${projects.length} active projects');
      return {
        'success': true,
        'data': projects,
        'message': 'Active projects fetched successfully',
      };
    } catch (e, stackTrace) {
      print('Error fetching active projects: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to fetch active projects',
      };
    }
  }

  // Get plots by project ID
  Future<Map<String, dynamic>> getPlotsByProjectId(String projectId) async {
    print('Fetching plots for project ID: $projectId');
    try {
      // final response = await _apiClient.get('${ApiConstants.projects}$projectId/plots/');
      final url = '${ApiConstants.availablePlotsData}?project=$projectId&status=available';
      print('Making API call to URL: $url');
      final response = await _apiClient.get(url);
      print('Plots API response status: ${response.statusCode}');
      print('Plots API response data type: ${response.data.runtimeType}');
      print('Plots API response data: $response.data');
      
      // Parse plots from response
      List<Plot> plots = [];
      
      // Handle different response formats
      if (response.data is List) {
        print('Parsing plots from list format, count: ${response.data.length}');
        final responseList = response.data as List;
        print('Response list items: $responseList');
        
        for (int i = 0; i < responseList.length; i++) {
          print('Item $i type: ${responseList[i].runtimeType}');
          print('Item $i data: ${responseList[i]}');
        }
        
        plots = responseList
            .whereType<Map<String, dynamic>>()
            .map((item) {
              print('Converting item to Plot: $item');
              try {
                final plot = Plot.fromJson(item);
                print('Successfully created plot: ${plot.id} - ${plot.plotNumber}');
                return plot;
              } catch (e) {
                print('Error converting item to Plot: $e');
                rethrow;
              }
            })
            .toList();
      } else if (response.data is Map) {
        // Check if it's a paginated response
        if (response.data['results'] is List) {
          print('Parsing plots from paginated format');
          plots = (response.data['results'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Plot.fromJson(item))
              .toList();
        } else if (response.data['data'] is List) {
          print('Parsing plots from data field format');
          plots = (response.data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Plot.fromJson(item))
              .toList();
        } else if (response.data['plots'] is List) {
          print('Parsing plots from plots field format');
          plots = (response.data['plots'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Plot.fromJson(item))
              .toList();
        } else {
          // Try to parse the entire map as a single plot
          print('Attempting to parse response as single plot object');
          try {
            final plot = Plot.fromJson(response.data);
            plots = [plot];
          } catch (e) {
            print('Failed to parse response as single plot: $e');
          }
        }
      } else {
        print('Unexpected response format: ${response.data.runtimeType}');
      }
      
      print('Successfully parsed ${plots.length} plots');
      if (plots.isEmpty) {
        print('WARNING: No plots were parsed from the response!');
        print('Response data was: ${response.data}');
        print('Response data type: ${response.data.runtimeType}');
      }
      return {
        'success': true,
        'data': plots,
        'message': 'Plots fetched successfully',
      };
    } catch (e, stackTrace) {
      print('Error fetching plots: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to fetch plots',
      };
    }
  }

  // Create visit
  Future<Map<String, dynamic>> createVisit(CreateVisitRequest request) async {
    try {
      print('Creating visit for project ID: ${request.projectId}');
      final formData = request.toFormData();
      final response = await _apiClient.post(
        ApiConstants.createVisits,
        data: formData,
      );
      print('Visit creation response status: ${response.statusCode}');
      print('Visit creation response data: $response.data');
      
      return {
        'success': true,
        'data': response.data,
        'message': 'Visit created successfully',
      };
    } catch (e, stackTrace) {
      print('Error creating visit: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to create visit',
      };
    }
  }

  // Get visits
  Future<Map<String, dynamic>> getVisits() async {
    try {
      print('Fetching visits from API...');
      final response = await _apiClient.get(ApiConstants.visits);
      print('Visits API response status: ${response.statusCode}');
      print('Visits API response data type: ${response.data.runtimeType}');
      print('Visits API response data: $response.data');
      
      // Parse visits from response
      List<Visit> visits = [];
      
      // Handle different response formats
      if (response.data is List) {
        print('Parsing visits from list format, count: ${response.data.length}');
        visits = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) {
              try {
                return Visit.fromJson(item);
              } catch (e) {
                print('Error parsing individual visit item: $e');
                print('Problematic item: $item');
                return null;
              }
            })
            .where((visit) => visit != null)
            .map((visit) => visit!)
            .toList();
      } else if (response.data is Map) {
        // Check if it's a paginated response
        if (response.data['results'] is List) {
          print('Parsing visits from paginated format');
          visits = (response.data['results'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return Visit.fromJson(item);
                } catch (e) {
                  print('Error parsing individual visit item: $e');
                  print('Problematic item: $item');
                  return null;
                }
              })
              .where((visit) => visit != null)
              .map((visit) => visit!)
              .toList();
        } else if (response.data['data'] is List) {
          print('Parsing visits from data field format');
          visits = (response.data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return Visit.fromJson(item);
                } catch (e) {
                  print('Error parsing individual visit item: $e');
                  print('Problematic item: $item');
                  return null;
                }
              })
              .where((visit) => visit != null)
              .map((visit) => visit!)
              .toList();
        } else if (response.data['visits'] is List) {
          print('Parsing visits from visits field format');
          visits = (response.data['visits'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return Visit.fromJson(item);
                } catch (e) {
                  print('Error parsing individual visit item: $e');
                  print('Problematic item: $item');
                  return null;
                }
              })
              .where((visit) => visit != null)
              .map((visit) => visit!)
              .toList();
        } else {
          // Try to parse the entire map as a single visit
          print('Attempting to parse response as single visit object');
          try {
            final visit = Visit.fromJson(response.data);
            visits = [visit];
          } catch (e) {
            print('Failed to parse response as single visit: $e');
            print('Problematic data: ${response.data}');
          }
        }
      } else {
        print('Unexpected response format for visits: ${response.data.runtimeType}');
      }
      
      print('Successfully parsed ${visits.length} visits');
      return {
        'success': true,
        'data': visits,
        'message': 'Visits fetched successfully',
      };
    } catch (e, stackTrace) {
      print('Error fetching visits: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to fetch visits',
      };
    }
  }

  // Register device for notifications
  Future<Map<String, dynamic>> registerDeviceForNotifications(NotificationRegisterRequestModel request) async {
    try {
      print('Registering device for notifications with token: ${request.registrationToken}');
      final response = await _apiClient.post(
        ApiConstants.notificationRegisterDevice,
        data: request.toJson(),
      );
      print('Notification registration response status: ${response.statusCode}');
      print('Notification registration response data: $response.data');
      
      return {
        'success': true,
        'data': response.data,
        'message': 'Device registered for notifications successfully',
      };
    } catch (e, stackTrace) {
      print('Error registering device for notifications: $e');
      print('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to register device for notifications',
      };
    }
  }
}

// Plot model for API response
class Plot {
  final int id;
  final String plotNumber;
  final int projectId;
  final String? projectName;
  final double area;
  final double? saleableSize;
  final double? sizeSqYd;
  final double price;
  final double? priceWithPlc;
  final bool plc;
  final bool plcApplied;
  final double? plcPercentage;
  final String dimensions;
  final String facing;
  final String remark;
  final String status;
  final double? width;
  final double? length;
  final String? sitePlanUrl;
  final String? primaryImage;
  final int imagesCount;
  final bool hasActiveHold;
  final bool hasActiveBooking;
  final String? createdAt;

  const Plot({
    required this.id,
    required this.plotNumber,
    required this.projectId,
    this.projectName,
    required this.area,
    this.saleableSize,
    this.sizeSqYd,
    required this.price,
    this.priceWithPlc,
    this.plc = false,
    this.plcApplied = false,
    this.plcPercentage,
    required this.dimensions,
    required this.facing,
    required this.remark,
    required this.status,
    this.width,
    this.length,
    this.sitePlanUrl,
    this.primaryImage,
    this.imagesCount = 0,
    this.hasActiveHold = false,
    this.hasActiveBooking = false,
    this.createdAt,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    // Map plot_code to plotNumber
    final plotCode = json['plot_code'];
    final plotNumber = plotCode != null 
        ? plotCode.toString() 
        : json['plot_number'] ?? json['plotNumber'] ?? '';
    
    // Map project field (can be int or string)
    int projectId = 0;
    if (json['project'] != null) {
      if (json['project'] is int) {
        projectId = json['project'] as int;
      } else if (json['project'] is String) {
        projectId = int.tryParse(json['project']) ?? 0;
      }
    } else if (json['project_id'] != null) {
      projectId = json['project_id'] is int 
          ? json['project_id'] as int 
          : (json['project_id'] is String ? int.tryParse(json['project_id']) ?? 0 : 0);
    } else if (json['projectId'] != null) {
      projectId = json['projectId'] is int 
          ? json['projectId'] as int 
          : (json['projectId'] is String ? int.tryParse(json['projectId']) ?? 0 : 0);
    }
    
    // Map area - prefer total_area, fallback to area
    final area = _parseDouble(json['total_area']) ?? 
                 _parseDouble(json['area']) ?? 0.0;
    
    // Build dimensions from width and length if available
    String dimensions;
    if (json['width'] != null && json['length'] != null) {
      final width = _parseDouble(json['width']) ?? 0.0;
      final length = _parseDouble(json['length']) ?? 0.0;
      dimensions = '${width.toStringAsFixed(0)} x ${length.toStringAsFixed(0)}';
    } else {
      dimensions = json['dimensions'] ?? '';
    }
    
    // Map facing - prefer facing_display for display, but store both
    final facing = json['facing_display'] ?? json['facing'] ?? '';
    
    // Map status_display to remark
    final remark = json['status_display'] ?? json['remark'] ?? '';
    
    return Plot(
      id: json['id'] ?? json['plot_id'] ?? 0,
      plotNumber: plotNumber,
      projectId: projectId,
      projectName: json['project_name']?.toString(),
      area: area,
      saleableSize: _parseDouble(json['saleable_size']),
      sizeSqYd: _parseDouble(json['size_sq_yd']),
      price: _parseDouble(json['price']) ?? 0.0,
      priceWithPlc: _parseDouble(json['price_with_plc']),
      plc: _parseBool(json['plc']),
      plcApplied: _parseBool(json['plc_applied']),
      plcPercentage: _parseDouble(json['plc_percentage']),
      dimensions: dimensions,
      facing: facing,
      remark: remark,
      status: json['status']?.toString() ?? 'available',
      width: _parseDouble(json['width']),
      length: _parseDouble(json['length']),
      sitePlanUrl: json['site_plan_url']?.toString(),
      primaryImage: json['primary_image']?.toString(),
      imagesCount: json['images_count'] is int 
          ? json['images_count'] as int 
          : (json['images_count'] is String 
              ? int.tryParse(json['images_count']) ?? 0 
              : 0),
      hasActiveHold: json['has_active_hold'] == true || json['has_active_hold'] == 'true',
      hasActiveBooking: json['has_active_booking'] == true || json['has_active_booking'] == 'true',
      createdAt: json['created_at']?.toString(),
    );
  }

  double get effectivePrice => priceWithPlc ?? price;

  // Helper method to parse double values from either string or number
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plot_code': plotNumber,
      'plot_number': plotNumber,
      'project': projectId,
      'project_id': projectId,
      'project_name': projectName,
      'total_area': area,
      'area': area,
      'saleable_size': saleableSize,
      'size_sq_yd': sizeSqYd,
      'price': price,
      'price_with_plc': priceWithPlc,
      'plc': plc,
      'plc_applied': plcApplied,
      'plc_percentage': plcPercentage,
      'width': width,
      'length': length,
      'dimensions': dimensions,
      'facing': facing,
      'facing_display': facing,
      'status': status,
      'status_display': remark,
      'remark': remark,
      'site_plan_url': sitePlanUrl,
      'primary_image': primaryImage,
      'images_count': imagesCount,
      'has_active_hold': hasActiveHold,
      'has_active_booking': hasActiveBooking,
      'created_at': createdAt,
    };
  }

  // Convert to local model Plot
  local_model.Plot toLocalModel() {
    return local_model.Plot(
      id: id.toString(),
      plotNumber: plotNumber,
      projectId: projectId.toString(),
      area: area,
      price: price,
      priceWithPlc: priceWithPlc,
      plc: plc,
      plcApplied: plcApplied,
      plcPercentage: plcPercentage,
      dimensions: dimensions,
      facing: facing,
      remark: remark,
      saleableSize: saleableSize,
      sizeSqYd: sizeSqYd,
      status: status,
      width: width,
      length: length,
      sitePlanUrl: sitePlanUrl,
      primaryImage: primaryImage,
      hasActiveHold: hasActiveHold,
      hasActiveBooking: hasActiveBooking,
      createdAt: createdAt,
    );
  }
}