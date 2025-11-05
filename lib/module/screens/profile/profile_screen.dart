import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../global/widgets/profile_picture.dart';
import '../../global/widgets/profile_text_field.dart';
import '../../global/widgets/custom_button.dart';
import '../../providers/profile_provider.dart';
import '../../../config/constant/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../../main.dart';
import 'package:image_picker/image_picker.dart';

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
    if (state.profile != null) {
      _fullNameController.text = state.profile!.fullName ?? '';
      _emailController.text = state.profile!.user?.email ?? '';
      _teamLeaderNameController.text = state.profile!.teamLeaderName ?? '';
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

  // Clear field errors
  void _clearFieldErrors() {
    setState(() {
      _fullNameError = null;
      _emailError = null;
      _teamLeaderNameError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    // Update controllers when profile state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllers(profileState);
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildProfileSettingsHeader(),
                      const SizedBox(height: 32),
                      _buildProfilePicture(profileState),
                      const SizedBox(height: 32),
                      _buildProfileForm(profileState),
                      const SizedBox(height: 32),
                      _buildActionButtons(profileState),
                    ],
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
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Update your profile details.',
          style: AppFonts.getFont(
            weight: AppFonts.regular,
            fontSize: 16,
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
        size: 120,
      ),
    );
  }

  Widget _buildProfileForm(ProfileState state) {
    return Column(
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
          const SizedBox(height: 4),
          Text(
            _fullNameError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 20),
        
        // Phone Number Field (Read-only)
        ProfileTextField(
          titleText: 'Phone Number',
          isMandatory: true,
          controller: TextEditingController(text: state.profile?.phoneNumber ?? ''),
          enabled: false,
          maxLength: 10,
          isReadOnly: true,
        ),
        const SizedBox(height: 20),
        
        // Rera Number Field (Read-only)
        ProfileTextField(
          titleText: 'Rera Number',
          isMandatory: state.profile?.reraNumber?.isNotEmpty ?? false,
          controller: TextEditingController(text: state.profile?.reraNumber ?? ''),
          enabled: false,
          isReadOnly: true,
        ),
        const SizedBox(height: 20),
        
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
          const SizedBox(height: 4),
          Text(
            _teamLeaderNameError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 20),
        
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
  }

  Widget _buildActionButtons(ProfileState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomButton(
          width: 100,
          text: 'Cancel',
          onPressed: state.isEditing ? () {
            ref.read(profileProvider.notifier).toggleEditMode();
            // Reset controllers to original values
            if (state.profile != null) {
              _fullNameController.text = state.profile!.fullName ?? '';
              _emailController.text = state.profile!.user?.email ?? '';
              _teamLeaderNameController.text = state.profile!.teamLeaderName ?? '';
            }
          } : null,
          backgroundColor: const Color(0xfff5f5f5),
          textColor: Colors.black,
          height: 48,
          borderRadius: 4,
        ),
        CustomButton(
          width: 100,
          text: 'Update',
          onPressed: state.isEditing ? () {
            ref.read(profileProvider.notifier).saveProfile();
          } : null,
          backgroundColor: AppColors.primaryColor,
          textColor: Colors.white,
          height: 48,
          borderRadius: 4,
          isLoading: state.isLoading,
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: AppFonts.getFont(
              weight: AppFonts.semiBold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
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
                'Cancel',
                style: AppFonts.getFont(
                  weight: AppFonts.medium,
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle logout logic here
                // For now, just show a snackbar using global key
                scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Logout functionality to be implemented'),
                    backgroundColor: AppColors.primaryColor,
                  ),
                );
              },
              child: Text(
                'Logout',
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