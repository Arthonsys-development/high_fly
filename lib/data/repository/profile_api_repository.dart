import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:highfly/config/network/api_client.dart';
import 'package:highfly/config/network/api_constants.dart';
import 'package:highfly/data/models/response_model/profile_model.dart';

class ProfileApiRepository {
  final ApiClient _apiClient = ApiClient();

  // Get user profile
  Future<ProfileResponseData> getProfile() async {
    try {
      debugPrint('🔍 ProfileApiRepository: Fetching user profile...');
      
      final response = await _apiClient.get(
        ApiConstants.profileData,
      );

      debugPrint('✅ ProfileApiRepository: Profile fetched successfully');
      debugPrint('📊 ProfileApiRepository: Response data: ${response.data}');

      // Parse the profile data from the response
      if (response.data is Map<String, dynamic>) {
        final profileData = ProfileResponseData.fromJson(response.data['data'] ?? response.data);
        return profileData;
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      debugPrint('❌ ProfileApiRepository: Error fetching profile - ${e.message}');
      debugPrint('📊 ProfileApiRepository: Error response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Profile not found');
      } else {
        throw Exception('Failed to fetch profile: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ ProfileApiRepository: Unexpected error - $e');
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Update user profile
  Future<ProfileResponseData> updateProfile(ProfileResponseData currentProfile, Map<String, dynamic> updateData) async {
    try {
      debugPrint('🔄 ProfileApiRepository: Updating user profile...');
      debugPrint('📊 ProfileApiRepository: Update data: $updateData');
      
      // Ensure required fields are included in the update
      final completeData = Map<String, dynamic>.from(updateData);
      
      // Add required fields from current profile if not present in updateData
      if (!completeData.containsKey('phone_number') && currentProfile.phoneNumber != null) {
        completeData['phone_number'] = currentProfile.phoneNumber;
      }
      
      if (!completeData.containsKey('rera_number') && currentProfile.reraNumber != null) {
        completeData['rera_number'] = currentProfile.reraNumber;
      }
      
      if (!completeData.containsKey('id_number') && currentProfile.idNumber != null) {
        completeData['id_number'] = currentProfile.idNumber;
      }
      
      // Add other important fields from current profile to maintain data integrity
      if (!completeData.containsKey('full_name') && currentProfile.fullName != null) {
        completeData['full_name'] = currentProfile.fullName;
      }
      
      if (!completeData.containsKey('team_leader_name') && currentProfile.teamLeaderName != null) {
        completeData['team_leader_name'] = currentProfile.teamLeaderName;
      }
      
      if (!completeData.containsKey('address') && currentProfile.address != null) {
        completeData['address'] = currentProfile.address;
      }
      
      if (!completeData.containsKey('experience_years') && currentProfile.experienceYears != null) {
        completeData['experience_years'] = currentProfile.experienceYears;
      }
      
      if (!completeData.containsKey('specialization') && currentProfile.specialization != null) {
        completeData['specialization'] = currentProfile.specialization;
      }
      
      if (!completeData.containsKey('commission_rate') && currentProfile.commissionRate != null) {
        completeData['commission_rate'] = currentProfile.commissionRate;
      }
      
      debugPrint('📊 ProfileApiRepository: Complete update data: $completeData');

      final response = await _apiClient.patch(
        ApiConstants.profileData,
        data: completeData,
      );

      debugPrint('✅ ProfileApiRepository: Profile updated successfully');
      debugPrint('📊 ProfileApiRepository: Response data: ${response.data}');

      // Parse the profile data from the response
      if (response.data is Map<String, dynamic>) {
        final profileData = ProfileResponseData.fromJson(response.data['data'] ?? response.data);
        return profileData;
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      debugPrint('❌ ProfileApiRepository: Error updating profile - ${e.message}');
      debugPrint('📊 ProfileApiRepository: Error response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        if (errors != null) {
          throw Exception('Validation failed: $_formatValidationErrors(errors)');
        }
        throw Exception('Invalid data provided');
      } else {
        throw Exception('Failed to update profile: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ ProfileApiRepository: Unexpected error - $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile photo
  Future<ProfileResponseData> uploadProfilePhoto(String imagePath) async {
    try {
      debugPrint('📸 ProfileApiRepository: Uploading profile photo...');
      
      final formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(
          imagePath,
          filename: 'profile_image.jpg',
        ),
      });

      // Try different possible endpoints for photo upload
      final endpoints = [
        (ApiConstants.profileData),
        (ApiConstants.profileData),
        ApiConstants.profileData,
      ];
      
      ProfileResponseData? profileData;
      String? lastError;
      
      for (final endpoint in endpoints) {
        try {
          debugPrint('📸 ProfileApiRepository: Trying endpoint: $endpoint');
          final response = await _apiClient.patch(endpoint, data: formData);
          
          debugPrint('✅ ProfileApiRepository: Profile photo uploaded successfully');
          debugPrint('📊 ProfileApiRepository: Response data: ${response.data}');
          
          // Parse the profile data from the response
          if (response.data is Map<String, dynamic>) {
            profileData = ProfileResponseData.fromJson(response.data['data'] ?? response.data);
            break;
          }
        } on DioException catch (e) {
          lastError = e.message;
          debugPrint('❌ ProfileApiRepository: Endpoint $endpoint failed - ${e.message}');
          if (e.response?.data != null) {
            debugPrint('📊 ProfileApiRepository: Error response: ${e.response?.data}');
          }
          continue;
        }
      }
      
      if (profileData != null) {
        return profileData;
      } else {
        throw Exception('Failed to upload photo: $lastError');
      }
    } on DioException catch (e) {
      debugPrint('❌ ProfileApiRepository: Error uploading photo - ${e.message}');
      debugPrint('📊 ProfileApiRepository: Error response: ${e.response?.data}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to upload photo: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ ProfileApiRepository: Unexpected error - $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Helper method to format validation errors
  String _formatValidationErrors(Map<String, dynamic> errors) {
    final errorMessages = <String>[];
    errors.forEach((field, messages) {
      if (messages is List) {
        errorMessages.add('$field: ${messages.join(', ')}');
      }
    });
    return errorMessages.join('; ');
  }
}