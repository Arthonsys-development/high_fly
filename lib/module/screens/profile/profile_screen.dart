import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../global/widgets/profile_picture.dart';
import '../../global/widgets/profile_text_field.dart';
import '../../global/widgets/custom_button.dart';
import '../../providers/profile_provider.dart';
import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/response_model/profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _teamLeaderNameController;
  
  // Error messages for individual fields
  String? _fullNameError;
  String? _emailError;
  String? _teamLeaderNameError;
  
  // Track previous profile to avoid unnecessary controller updates
  ProfileResponseData? _previousProfile;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _teamLeaderNameController = TextEditingController();
    
    // Load profile data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _teamLeaderNameController.dispose();
    super.dispose();
  }

  void _updateControllers(ProfileState state) {
    // Never update controllers while user is editing to avoid overwriting input
    if (state.isEditing) {
      return;
    }
    
    if (state.profile != null) {
      final currentProfile = state.profile!;
      
      // Check if this is a different profile (by ID) or initial load
      // This ensures we update on initial load or when switching profiles
      final isDifferentProfile = _previousProfile == null || 
          _previousProfile!.id != currentProfile.id;
      
      // Only update controllers on initial load or when profile ID changed
      // We don't update when user is typing because that would overwrite their input
      if (_isInitialLoad || isDifferentProfile) {
        _fullNameController.text = currentProfile.fullName ?? '';
        _emailController.text = currentProfile.user?.email ?? '';
        _teamLeaderNameController.text = currentProfile.teamLeaderName ?? '';
        
        _previousProfile = currentProfile;
        _isInitialLoad = false;
      }
    }
  }

  void _parseFieldErrors(String? error) {
    if (error == null) {
      _fullNameError = null;
      _emailError = null;
      _teamLeaderNameError = null;
      return;
    }
    
    // Reset errors
    _fullNameError = null;
    _emailError = null;
    _teamLeaderNameError = null;
    
    // Parse validation errors
    if (error.contains('full_name')) {
      _fullNameError = 'Please enter a valid full name';
    }
    
    if (error.contains('email')) {
      _emailError = 'Please enter a valid email address';
    }
    
    if (error.contains('team_leader_name')) {
      _teamLeaderNameError = 'Please enter a valid team leader name';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    // Update controllers when profile state changes (only when not editing)
    if (!profileState.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateControllers(profileState);
      });
    }
    
    // Handle errors and edit mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only parse errors if there's an error and we're not currently editing
      if (profileState.error != null && !profileState.isEditing) {
        _parseFieldErrors(profileState.error);
      } else if (profileState.isEditing) {
        // Clear field errors when entering edit mode
        setState(() {
          _fullNameError = null;
          _emailError = null;
          _teamLeaderNameError = null;
        });
      }
    });

    // Show error dialog if there's an error and we're not editing
    if (profileState.error != null && !profileState.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(context, profileState.error!);
        ref.read(profileProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : profileState.profile == null
              ? const Center(
                  child: Text('No profile data available'),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(kIsWeb ? 32.0 : 20.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: kIsWeb ? 800 : double.infinity,
                      ),
                      child: Column(
                        children: [
                          _buildProfileSettingsHeader(),
                          SizedBox(height: kIsWeb ? 40 : 32),
                          _buildProfilePicture(profileState),
                          SizedBox(height: kIsWeb ? 40 : 32),
                          _buildProfileForm(profileState),
                          if (profileState.isEditing) ...[
                            SizedBox(height: kIsWeb ? 40 : 32),
                            _buildActionButtons(profileState),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileSettingsHeader() {
    return Column(
      children: [
        Text(
          'PROFILE SETTINGS',
          style: AppFonts.getFont(
            weight: AppFonts.bold,
            fontSize: kIsWeb ? 28 : 24,
            color: Colors.black,
          ).copyWith(
            letterSpacing: kIsWeb ? 1.2 : 0,
          ),
        ),
        SizedBox(height: kIsWeb ? 12 : 8),
        Text(
          'Update your profile details.',
          style: AppFonts.getFont(
            weight: AppFonts.regular,
            fontSize: kIsWeb ? 18 : 16,
            color: AppColors.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture(ProfileState state) {
    return Center(
      child: ProfilePicture(
        imageUrl: state.profile?.profileImage,
        onEditPressed: () {
          _showImageSourceDialog();
        },
        size: kIsWeb ? 150 : 120,
      ),
    );
  }

  Widget _buildProfileForm(ProfileState state) {
    final formContent = Column(
      children: [
        // Full Name Field
        ProfileTextField(
          titleText: 'Full Name',
          isMandatory: true,
          maxLength: 30,
          controller: _fullNameController,
          enabled: state.isEditing,
          onChanged: (value) {
            ref.read(profileProvider.notifier).updateField('fullName', value);
          },
          onEditPressed: state.isEditing ? null : () {
            ref.read(profileProvider.notifier).toggleEditMode();
          },
          isReadOnly: !state.isEditing,
        ),
        if (_fullNameError != null) ...[
          SizedBox(height: kIsWeb ? 6 : 4),
          Padding(
            padding: EdgeInsets.only(left: kIsWeb ? 16 : 0),
            child: Text(
              _fullNameError!,
              style: TextStyle(
                color: Colors.red,
                fontSize: kIsWeb ? 13 : 12,
              ),
            ),
          ),
        ],
        SizedBox(height: kIsWeb ? 24 : 20),
        
        // Phone Number Field (Read-only)
        ProfileTextField(
          titleText: 'Phone Number',
          isMandatory: true,
          controller: TextEditingController(text: state.profile?.phoneNumber ?? ''),
          enabled: false,
          maxLength: 10,
          isReadOnly: true,
        ),
        SizedBox(height: kIsWeb ? 24 : 20),
        
        // Rera Number Field (Read-only)
        ProfileTextField(
          titleText: 'Rera Number',
          isMandatory: state.profile?.reraNumber?.isNotEmpty ?? false,
          controller: TextEditingController(text: state.profile?.reraNumber ?? ''),
          enabled: false,
          isReadOnly: true,
        ),
        SizedBox(height: kIsWeb ? 24 : 20),
        
        // Team Leader Name Field
        ProfileTextField(
          titleText: 'Team Leader Name',
          isMandatory: state.profile?.teamLeaderName?.isNotEmpty ?? false,
          controller: _teamLeaderNameController,
          enabled: state.isEditing,
          maxLength: 30,
          onChanged: (value) {
            ref.read(profileProvider.notifier).updateField('teamLeaderName', value);
          },
          onEditPressed: state.isEditing ? null : () {
            ref.read(profileProvider.notifier).toggleEditMode();
          },
          isReadOnly: !state.isEditing,
        ),
        if (_teamLeaderNameError != null) ...[
          SizedBox(height: kIsWeb ? 6 : 4),
          Padding(
            padding: EdgeInsets.only(left: kIsWeb ? 16 : 0),
            child: Text(
              _teamLeaderNameError!,
              style: TextStyle(
                color: Colors.red,
                fontSize: kIsWeb ? 13 : 12,
              ),
            ),
          ),
        ],
        SizedBox(height: kIsWeb ? 24 : 20),
        
        // ID Number Field (Read-only)
        ProfileTextField(
          titleText: 'ID Number',
          isMandatory: state.profile?.idNumber?.isNotEmpty ?? false,
          controller: TextEditingController(text: state.profile?.idNumber ?? ''),
          enabled: false,
          isReadOnly: true,
        ),
      ],
    );

    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: formContent,
      );
    } else {
      return formContent;
    }
  }

  Widget _buildActionButtons(ProfileState state) {
    if (kIsWeb) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              width: 140,
              text: 'Cancel',
              onPressed: () {
                ref.read(profileProvider.notifier).toggleEditMode();
                // Reset controllers to original values
                if (state.profile != null) {
                  _fullNameController.text = state.profile!.fullName ?? '';
                  _emailController.text = state.profile!.user?.email ?? '';
                  _teamLeaderNameController.text = state.profile!.teamLeaderName ?? '';
                }
              },
              backgroundColor: const Color(0xfff5f5f5),
              textColor: Colors.black,
              height: 52,
              borderRadius: 8,
            ),
            const SizedBox(width: 16),
            CustomButton(
              width: 140,
              text: 'Update',
              onPressed: () {
                ref.read(profileProvider.notifier).saveProfile();
              },
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.white,
              height: 52,
              borderRadius: 8,
              isLoading: state.isLoading,
            ),
          ],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomButton(
            width: 100,
            text: 'Cancel',
            onPressed: () {
              ref.read(profileProvider.notifier).toggleEditMode();
              // Reset controllers to original values
              if (state.profile != null) {
                _fullNameController.text = state.profile!.fullName ?? '';
                _emailController.text = state.profile!.user?.email ?? '';
                _teamLeaderNameController.text = state.profile!.teamLeaderName ?? '';
              }
            },
            backgroundColor: const Color(0xfff5f5f5),
            textColor: Colors.black,
            height: 48,
            borderRadius: 4,
          ),
          CustomButton(
            width: 100,
            text: 'Update',
            onPressed: () {
              ref.read(profileProvider.notifier).saveProfile();
            },
            backgroundColor: AppColors.primaryColor,
            textColor: Colors.white,
            height: 48,
            borderRadius: 4,
            isLoading: state.isLoading,
          ),
        ],
      );
    }
  }


  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Error',
            style: AppFonts.getFont(
              weight: AppFonts.semiBold,
              fontSize: 18,
              color: Colors.red,
            ),
          ),
          content: Text(
            error,
            style: AppFonts.getFont(
              weight: AppFonts.regular,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: AppFonts.getFont(
                  weight: AppFonts.medium,
                  fontSize: 14,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageSourceDialog() async {
    // On web, directly open gallery without showing dialog
    if (kIsWeb) {
      ref.read(profileProvider.notifier)
          .updateProfilePhotoFromSource(ImageSource.gallery);
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(profileProvider.notifier)
                      .updateProfilePhotoFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(profileProvider.notifier)
                      .updateProfilePhotoFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}