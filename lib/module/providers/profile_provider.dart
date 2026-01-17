import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/response_model/profile_model.dart';
import '../../data/repository/profile_api_repository.dart';
import '../../config/constant/app_strings.dart';
import '../../config/network/base_url_config.dart';

// Profile state class
class ProfileState {
  final ProfileResponseData? profile;
  final bool isLoading;
  final String? error;
  final bool isEditing;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isEditing = false,
  });

  ProfileState copyWith({
    ProfileResponseData? profile,
    bool? isLoading,
    String? error,
    bool? isEditing,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

// Profile notifier
class ProfileNotifier extends Notifier<ProfileState> {
  final ProfileApiRepository _profileApiRepository = ProfileApiRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  ProfileState build() {
    return const ProfileState(
      profile: null,
      isLoading: false,
    );
  }

  // Load profile data from API
  Future<void> loadProfile() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      debugPrint('🔄 ProfileNotifier: Loading profile from API...');
      
      final profileData = await _profileApiRepository.getProfile();
      
      debugPrint('✅ ProfileNotifier: Profile loaded successfully');
      state = state.copyWith(
        profile: profileData,
        isLoading: false,
      );
      
      // Sync data to secure storage after loading
      await _syncToSecureStorage(profileData);
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Error loading profile - $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Helper method to sync profile data to secure storage
  Future<void> _syncToSecureStorage(ProfileResponseData profileData) async {
    try {
      // Update fullName
      if (profileData.fullName != null && profileData.fullName!.isNotEmpty) {
        await _secureStorage.write(
          key: SharedPreferenceStrings.fullName, 
          value: profileData.fullName!
        );
        await _secureStorage.write(
          key: SharedPreferenceStrings.firstName, 
          value: profileData.fullName!
        );
        debugPrint('✅ ProfileNotifier: Full name synced to secure storage');
      }
      
      // Update profile photo if available
      if (profileData.profileImage != null && profileData.profileImage!.isNotEmpty) {
        // Use BaseUrlConfig to build the full image URL
        final profileImageUrl = BaseUrlConfig.buildImageUrl(profileData.profileImage);
        await _secureStorage.write(
          key: SharedPreferenceStrings.profilePhoto,
          value: profileImageUrl
        );
        debugPrint('✅ ProfileNotifier: Profile photo synced to secure storage');
      }
    } catch (e) {
      debugPrint('⚠️ ProfileNotifier: Error syncing to secure storage - $e');
    }
  }

  // Public method to refresh profile data
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  // Update profile field locally (for form editing)
  void updateField(String field, String value) {
    if (state.profile == null) return;
    
    ProfileResponseData updatedProfile;
    
    switch (field) {
      case 'fullName':
        updatedProfile = ProfileResponseData(
          id: state.profile!.id,
          user: state.profile!.user,
          phoneNumber: state.profile!.phoneNumber,
          reraNumber: state.profile!.reraNumber,
          idNumber: state.profile!.idNumber,
          profileImage: state.profile!.profileImage,
          idProofImage: state.profile!.idProofImage,
          teamLeaderName: state.profile!.teamLeaderName,
          status: state.profile!.status,
          isVerified: state.profile!.isVerified,
          address: state.profile!.address,
          experienceYears: state.profile!.experienceYears,
          specialization: state.profile!.specialization,
          commissionRate: state.profile!.commissionRate,
          fullName: value,
          createdAt: state.profile!.createdAt,
        );
        break;
      case 'email':
        // Email is part of the User object
        if (state.profile!.user != null) {
          final updatedUser = User(
            id: state.profile!.user!.id,
            email: value,
            firstName: state.profile!.user!.firstName,
            lastName: state.profile!.user!.lastName,
            phoneNumber: state.profile!.user!.phoneNumber,
            isPhoneVerified: state.profile!.user!.isPhoneVerified,
            profileImage: state.profile!.user!.profileImage,
          );
          
          updatedProfile = ProfileResponseData(
            id: state.profile!.id,
            user: updatedUser,
            phoneNumber: state.profile!.phoneNumber,
            reraNumber: state.profile!.reraNumber,
            idNumber: state.profile!.idNumber,
            profileImage: state.profile!.profileImage,
            idProofImage: state.profile!.idProofImage,
            teamLeaderName: state.profile!.teamLeaderName,
            status: state.profile!.status,
            isVerified: state.profile!.isVerified,
            address: state.profile!.address,
            experienceYears: state.profile!.experienceYears,
            specialization: state.profile!.specialization,
            commissionRate: state.profile!.commissionRate,
            fullName: state.profile!.fullName,
            createdAt: state.profile!.createdAt,
          );
        } else {
          return;
        }
        break;
      case 'teamLeaderName':
        updatedProfile = ProfileResponseData(
          id: state.profile!.id,
          user: state.profile!.user,
          phoneNumber: state.profile!.phoneNumber,
          reraNumber: state.profile!.reraNumber,
          idNumber: state.profile!.idNumber,
          profileImage: state.profile!.profileImage,
          idProofImage: state.profile!.idProofImage,
          teamLeaderName: value,
          status: state.profile!.status,
          isVerified: state.profile!.isVerified,
          address: state.profile!.address,
          experienceYears: state.profile!.experienceYears,
          specialization: state.profile!.specialization,
          commissionRate: state.profile!.commissionRate,
          fullName: state.profile!.fullName,
          createdAt: state.profile!.createdAt,
        );
        break;
      default:
        return;
    }
    
    state = state.copyWith(profile: updatedProfile);
  }

  // Save profile changes to API
  Future<void> saveProfile() async {
    if (state.profile == null) {
      state = state.copyWith(error: 'No profile data available');
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      debugPrint('💾 ProfileNotifier: Saving profile changes...');
      
      final updateData = <String, dynamic>{};
      
      if (state.profile?.fullName != null) {
        updateData['full_name'] = state.profile!.fullName;
      }
      
      if (state.profile?.user?.email != null) {
        updateData['email'] = state.profile!.user!.email;
      }
      
      if (state.profile?.teamLeaderName != null) {
        updateData['team_leader_name'] = state.profile!.teamLeaderName;
      }
      
      await _profileApiRepository.updateProfile(state.profile!, updateData);
      
      debugPrint('✅ ProfileNotifier: Profile saved successfully');
      // Allow loadProfile to proceed (it early-returns if already loading)
      state = state.copyWith(isLoading: false);
      // After saving, fetch the latest profile from API to ensure fresh data
      await loadProfile();
      // Ensure we exit edit mode
      state = state.copyWith(
        isEditing: false,
      );
    } on DioException catch (e) {
      debugPrint('❌ ProfileNotifier: API Error saving profile - ${e.message}');
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic> && errorData.containsKey('errors')) {
          // Format validation errors for display
          final errors = errorData['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessages.add('$field: ${messages.join(', ')}');
            }
          });
          state = state.copyWith(
            error: 'Validation failed: ${errorMessages.join('; ')}',
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            error: 'Failed to save profile: ${errorData.toString()}',
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          error: 'Failed to save profile: ${e.message}',
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Unexpected error saving profile - $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Update profile photo
  Future<void> updateProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        state = state.copyWith(isLoading: true, error: null);
        
        // Upload the image to the backend (use image.path to get the file path)
        await _profileApiRepository.uploadProfilePhoto(image.path);
        debugPrint('✅ ProfileNotifier: Profile image updated successfully');
        // Allow loadProfile to proceed and fetch the freshest data, including CDN URLs
        state = state.copyWith(isLoading: false);
        await loadProfile();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update profile photo: $e',
        isLoading: false,
      );
    }
  }

  // Update profile photo from a specific image source (camera or gallery)
  Future<void> updateProfilePhotoFromSource(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        state = state.copyWith(isLoading: true, error: null);

        // Upload the image to the backend (use image.path to get the file path)
        await _profileApiRepository.uploadProfilePhoto(image.path);
        debugPrint('✅ ProfileNotifier: Profile image updated successfully (from ${source.name})');
        state = state.copyWith(isLoading: false);
        await loadProfile();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update profile photo: $e',
        isLoading: false,
      );
    }
  }

  // Toggle edit mode
  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});