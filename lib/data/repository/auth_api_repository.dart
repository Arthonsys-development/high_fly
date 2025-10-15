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
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Registration failed',
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
      if (e.response != null) {
        debugPrint('Error response data: ${e.response?.data}');
        debugPrint('Error status code: ${e.response?.statusCode}');
      }
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Token verification failed: ${e.message}',
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
      print('Projects API response status: ${response.statusCode}');
      print('Projects API response data type: ${response.data.runtimeType}');
      print('Projects API response data: $response.data');
      
      // Parse projects from response
      List<Project> projects = [];
      
      // Handle different response formats
      if (response.data is List) {
        print('Parsing projects from list format, count: ${response.data.length}');
        projects = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => Project.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map) {
        // Check if it's a paginated response
        if (response.data['results'] is List) {
          print('Parsing projects from paginated format');
          projects = (response.data['results'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.data['data'] is List) {
          print('Parsing projects from data field format');
          projects = (response.data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.data['projects'] is List) {
          print('Parsing projects from projects field format');
          projects = (response.data['projects'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item as Map<String, dynamic>))
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
            .map((item) => Project.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map) {
        // Check if it's a paginated response
        if (response.data['results'] is List) {
          print('Parsing active projects from paginated format');
          projects = (response.data['results'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.data['data'] is List) {
          print('Parsing active projects from data field format');
          projects = (response.data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.data['projects'] is List) {
          print('Parsing active projects from projects field format');
          projects = (response.data['projects'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Project.fromJson(item as Map<String, dynamic>))
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
      final response = await _apiClient.get('${ApiConstants.availablePlotsData}?project=$projectId&status=available');
      print('Plots API response status: ${response.statusCode}');
      print('Plots API response data type: ${response.data.runtimeType}');
      print('Plots API response data: $response.data');
      
      // Parse plots from response
      List<Plot> plots = [];
      
      // Handle different response formats
      if (response.data is List) {
        print('Parsing plots from list format, count: ${response.data.length}');
        plots = (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => Plot.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.data is Map) {
        // Check if it's a paginated response
        if (response.data['results'] is List) {
          print('Parsing plots from paginated format');
          plots = (response.data['results'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Plot.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.data['data'] is List) {
          print('Parsing plots from data field format');
          plots = (response.data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Plot.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.data['plots'] is List) {
          print('Parsing plots from plots field format');
          plots = (response.data['plots'] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => Plot.fromJson(item as Map<String, dynamic>))
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
                return Visit.fromJson(item as Map<String, dynamic>);
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
                  return Visit.fromJson(item as Map<String, dynamic>);
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
                  return Visit.fromJson(item as Map<String, dynamic>);
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
                  return Visit.fromJson(item as Map<String, dynamic>);
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
  final double area;
  final double price;
  final String dimensions;
  final String facing;
  final String remark;
  final String status;

  Plot({
    required this.id,
    required this.plotNumber,
    required this.projectId,
    required this.area,
    required this.price,
    required this.dimensions,
    required this.facing,
    required this.remark,
    required this.status,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    return Plot(
      id: json['id'] ?? json['plot_id'] ?? 0,
      plotNumber: json['plot_number'] ?? json['plotNumber'] ?? '',
      projectId: json['project_id'] ?? json['projectId'] ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      dimensions: json['dimensions'] ?? '',
      facing: json['facing'] ?? '',
      remark: json['remark'] ?? '',
      status: json['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plot_number': plotNumber,
      'project_id': projectId,
      'area': area,
      'price': price,
      'dimensions': dimensions,
      'facing': facing,
      'remark': remark,
      'status': status,
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
      dimensions: dimensions,
      facing: facing,
      remark: remark,
    );
  }
}