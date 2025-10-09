import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/routes.dart';
import 'package:highfly/module/global/widgets/custom_button.dart';
import 'package:highfly/module/utils/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

// Import the new providers and models
import 'package:highfly/data/repository/auth_api_repository_provider.dart';
import 'package:highfly/data/models/request_models/auth_request_model.dart';
import 'package:highfly/data/repository/firebase_auth_repository.dart';

import '../../../config/constant/app_strings.dart';
import '../../../config/constant/const_assets.dart';
import '../../global/widgets/custom_text_field.dart';
import '../../utils/app_fonts.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool showOtpField = false;
  XFile? _pickedImage;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _reraNumberController = TextEditingController();
  final TextEditingController _teamLeaderNameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  
  // Loading state
  bool _isLoading = false;
  
  // Firebase auth repository
  final FirebaseAuthRepository _firebaseAuthRepository = FirebaseAuthRepository();

  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    // Dispose controllers
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _otpController.dispose();
    _reraNumberController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      print('🔥 Image Picker: Attempting to pick image from camera');
      
      // Check and request camera permission on mobile
      if (!kIsWeb) {
        try {
          final status = await Permission.camera.request();
          if (status != PermissionStatus.granted) {
            print('🔥 Image Picker: Camera permission denied');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Camera permission is required to take photos'),
                  backgroundColor: Colors.red,
                ),
              );
              
              // Open app settings if permanently denied
              if (status == PermissionStatus.permanentlyDenied) {
                await openAppSettings();
              }
            }
            return;
          }
        } catch (permissionError) {
          print('🔥 Image Picker: Permission error, trying to proceed anyway: $permissionError');
          // On some devices, we might still be able to pick an image even without explicit permission
          // This is a fallback approach
        }
      }
      
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      print('🔥 Image Picker: Camera result: ${pickedImage != null ? 'Image captured' : 'No image captured'}');
      
      if (pickedImage != null) {
        print('🔥 Image Picker: Processing captured image');
        
        if (kIsWeb) {
          print('🔥 Image Picker: Web platform detected');
          // For web, we need to read the image as bytes
          final bytes = await pickedImage.readAsBytes();
          print('🔥 Image Picker: Image bytes length: ${bytes.length}');
          
          if (!mounted) return;
          setState(() {
            _webImage = bytes;
            _pickedImage = pickedImage;
          });
          
          print('🔥 Image Picker: Web image state updated');
        } else {
          print('🔥 Image Picker: Mobile platform detected');
          // For mobile, we can use the file directly
          if (!mounted) return;
          setState(() {
            _pickedImage = pickedImage;
            _webImage = null; // Clear web image data for mobile
          });
          
          print('🔥 Image Picker: Mobile image state updated');
        }
      } else {
        print('🔥 Image Picker: No image was captured');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image captured'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('🔥 Image Picker: Error picking image from camera: $e');
      
      // Special handling for web camera errors
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera access denied or not supported by your browser. Please check browser permissions or try selecting from gallery.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image from camera: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Clear the selected image
  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _webImage = null;
    });
    print('🔥 Image Picker: Image cleared');
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      print('🔥 Image Picker: Attempting to pick image from gallery');
      
      // Check and request gallery permission on mobile
      if (!kIsWeb) {
        try {
          if (Platform.isAndroid) {
            // On Android 13+ this maps to READ_MEDIA_IMAGES
            var status = await Permission.photos.request();
            if (status != PermissionStatus.granted) {
              // Fallback for Android 12 and below
              status = await Permission.storage.request();
            }
            if (status != PermissionStatus.granted) {
              print('🔥 Image Picker: Gallery permission denied');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gallery permission is required to select photos'),
                    backgroundColor: Colors.red,
                  ),
                );
                if (status == PermissionStatus.permanentlyDenied) {
                  await openAppSettings();
                }
              }
              return;
            }
          } else if (Platform.isIOS) {
            // iOS: PHPicker does not require Photos permission; proceed without requesting
          }
        } catch (permissionError) {
          print('🔥 Image Picker: Permission error, trying to proceed anyway: $permissionError');
          // On some devices, we might still be able to pick an image even without explicit permission
        }
      }
      
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      print('🔥 Image Picker: Gallery result: ${pickedImage != null ? 'Image selected' : 'No image selected'}');
      
      if (pickedImage != null) {
        print('🔥 Image Picker: Processing selected image');
        
        if (kIsWeb) {
          print('🔥 Image Picker: Web platform detected');
          // For web, we need to read the image as bytes
          final bytes = await pickedImage.readAsBytes();
          print('🔥 Image Picker: Image bytes length: ${bytes.length}');
          
          if (!mounted) return;
          setState(() {
            _webImage = bytes;
            _pickedImage = pickedImage;
          });
          
          print('🔥 Image Picker: Web image state updated');
        } else {
          print('🔥 Image Picker: Mobile platform detected');
          // For mobile, we can use the file directly
          if (!mounted) return;
          setState(() {
            _pickedImage = pickedImage;
            _webImage = null; // Clear web image data for mobile
          });
          
          print('🔥 Image Picker: Mobile image state updated');
        }
      } else {
        print('🔥 Image Picker: No image was selected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('🔥 Image Picker: Error picking image from gallery: $e');
      
      // Special handling for web gallery errors
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery access denied or not supported by your browser. Please check browser permissions.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image from gallery: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    if (kIsWeb) {
      // On web, show both camera and gallery options
      // Modern browsers on mobile devices support camera access
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                ),
              ],
            ),
          );
        },
      );
    }
    
    return showDialog(
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
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePhotoSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PROFILE PHOTO",
              style: AppFonts.getFont(
                weight: AppFonts.medium,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: SizedBox(
                width: 5,
                height: 5,
                child: Image.asset(IconsAssets.star, color: Colors.red),
              ),
            )
          ],
        ),
        SizedBox(height: 20),
        GestureDetector(
          onTap: _showImageSourceDialog,
          onLongPress: _clearImage,
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: Radius.circular(50),
              padding: EdgeInsets.symmetric(horizontal: 2),
              color: AppColors.buttonBorderColor,
            ),
            child: Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(50)),
                color: AppColors.buttonBGColor,
              ),
              child: _pickedImage != null || _webImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: kIsWeb 
                          ? (_webImage != null
                              ? Image.memory(
                                  _webImage!,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('🔥 Image Picker: Error displaying web image: $error');
                                    return Icon(Icons.error, color: Colors.red);
                                  },
                                )
                              : Container())
                          : (_pickedImage != null
                              ? Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('🔥 Image Picker: Error displaying mobile image: $error');
                                    return Icon(Icons.error, color: Colors.red);
                                  },
                                )
                              : Container()),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 30,
                          width: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            color: AppColors.buttonBorderColor,
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                        Text(
                          "Tap to upload",
                          style: AppFonts.getFont(
                            weight: AppFonts.regular,
                            fontSize: 11,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                ImageAssets.highFlyLogo,
                width: 100,
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                SignInScreenString.heading1,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Text(
                SignInScreenString.heading2,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            _buildProfilePhotoSection(),
            SizedBox(height: 20),
            CustomTextField(
              controller: _fullNameController,
              titleText: 'Full Name',
              hintText: 'Enter your full name',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 50,
            ),
            SizedBox(height: 20),
            CustomTextField(
              controller: _phoneNumberController,
              titleText: 'Phone Number',
              hintText: '123456789',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 10,
              keyboardType: TextInputType.phone,
            ),

            if(showOtpField)...[
              SizedBox(height: 20),
              CustomTextField(
                controller: _otpController,
                titleText: 'OTP',
                hintText: 'Enter 6-digit OTP',
                borderRadius: 6,
                contentSpace: 8,
                maxLength: 6,
                keyboardType: TextInputType.number,
              ),
            ],

            SizedBox(height: 20),
            CustomTextField(
              controller: _reraNumberController,
              titleText: 'RERA Number',
              hintText: 'Enter your RERA number',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 30,
            ),
            SizedBox(height: 20),
            CustomTextField(
              controller: _teamLeaderNameController,
              titleText: 'Team Leader Name',
              hintText: 'Enter team leader name',
              borderRadius: 8,
              contentSpace: 12,
              maxLength: 50,
            ),
            SizedBox(height: 20),
            CustomTextField(
              controller: _idNumberController,
              titleText: 'ID Number',
              hintText: 'Enter your ID number',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 30,
            ),
            SizedBox(height: 30),

            submitButton(),

            SizedBox(height: 30),

            GestureDetector(
              onTap: () {
                context.pop();
              },
              child: Text(
                'Already have an account? Sign In',
                style: AppFonts.getFont(
                  weight: FontWeight.w500,
                  fontSize: 16,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),

            SizedBox(height: 30)
          ],
        ),
      ),
    );
  }

  Widget _buildTabletDesktopLayout() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 600 : 500,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 20,
          ),
          padding: EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                ImageAssets.highFlyLogo,
                width: Responsive.isDesktop(context) ? 120 : 100,
              ),
              SizedBox(height: 30),
              Text(
                SignInScreenString.heading1,
                style: TextStyle(
                  fontSize: Responsive.isDesktop(context) ? 36 : 32,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                SignInScreenString.heading2,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              _buildProfilePhotoSection(),
              SizedBox(height: 30),
              // Two-column layout for desktop, single column for tablet
              if (Responsive.isDesktop(context))
                _buildDesktopFormFields()
              else
                _buildTabletFormFields(),
              SizedBox(height: 40),

              submitButton(),

              SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  context.go(Routes.signIn);
                },
                child: Text(
                  'Already have an account? Sign In',
                  style: AppFonts.getFont(
                    weight: FontWeight.w500,
                    fontSize: 16,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFormFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _fullNameController,
                titleText: 'Full Name',
                hintText: 'Enter your full name',
                borderRadius: 8,
                contentSpace: 12,
                maxLength: 13,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: CustomTextField(
                controller: _phoneNumberController,
                titleText: 'Phone Number',
                hintText: '123456789',
                borderRadius: 8,
                contentSpace: 12,
                maxLength: 10,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          children: [

            if(showOtpField)...[
              Expanded(
                child: CustomTextField(
                  controller: _otpController,
                  titleText: 'OTP',
                  hintText: 'Enter 6-digit OTP',
                  borderRadius: 8,
                  contentSpace: 12,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 20),
            ],

            Expanded(
              child: CustomTextField(
                controller: _reraNumberController,
                titleText: 'RERA Number',
                hintText: 'Enter your RERA number',
                borderRadius: 8,
                contentSpace: 12,
                maxLength: 13,
              ),
            ),
          ],
        ),

        SizedBox(height: 20),
        CustomTextField(
          controller: _teamLeaderNameController,
          titleText: 'Team Leader Name',
          hintText: 'Enter team leader name',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 50,
        ),

        SizedBox(height: 20),
        CustomTextField(
          controller: _idNumberController,
          titleText: 'ID Number',
          hintText: 'Enter your ID number',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 13,
        ),
      ],
    );
  }

  Widget _buildTabletFormFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _fullNameController,
          titleText: 'Full Name',
          hintText: 'Enter your full name',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 50,
        ),
        SizedBox(height: 20),
        CustomTextField(
          controller: _phoneNumberController,
          titleText: 'Phone Number',
          hintText: '123456789',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 10,
          keyboardType: TextInputType.phone,
        ),

        if(showOtpField)...[
          SizedBox(height: 20),
          CustomTextField(
            controller: _otpController,
            titleText: 'OTP',
            hintText: 'Enter 6-digit OTP',
            borderRadius: 8,
            contentSpace: 12,
            maxLength: 6,
            keyboardType: TextInputType.number,
          ),
        ],

        SizedBox(height: 20),
        CustomTextField(
          controller: _reraNumberController,
          titleText: 'RERA Number',
          hintText: 'Enter your RERA number',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 36,
        ),
        SizedBox(height: 20),
        CustomTextField(
          controller: _teamLeaderNameController,
          titleText: 'Team Leader Name',
          hintText: 'Enter team leader name',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 50,
        ),
        SizedBox(height: 20),
        CustomTextField(
          controller: _idNumberController,
          titleText: 'ID Number',
          hintText: 'Enter your ID number',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 36,
        ),
      ],
    );
  }

  // Send OTP to phone number
  Future<void> _sendOTP() async {
    final phoneNumber = "+91${_phoneNumberController.text.trim()}";
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firebaseAuthRepository.sendOTP(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          setState(() {
            _isLoading = false;
            showOtpField = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        },
        onAutoVerificationCompleted: () {
          setState(() {
            _isLoading = false;
            showOtpField = false;
          });
          
          // Navigate to dashboard since auto-verification completed
          context.go(Routes.dashboardScreen);
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Verify OTP and register user
  Future<void> _verifyOTPAndRegister() async {
    final fullName = _fullNameController.text.trim();
    final phoneNumber = "+91${_phoneNumberController.text.trim()}";
    final otp = _otpController.text.trim();
    final reraNumber = _reraNumberController.text.trim();
    final teamLeaderName = _teamLeaderNameController.text.trim();
    final idNumber = _idNumberController.text.trim();
    
    // Validate form fields
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (reraNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your RERA number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (teamLeaderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter team leader name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (idNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your ID number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Check if profile photo is required
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a profile photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First, verify the OTP with Firebase
      final userCredential = await _firebaseAuthRepository.verifyOTP(
        otpCode: otp,
        verificationId: _firebaseAuthRepository.verificationId,
      );
      
      // Get the Firebase ID token
      final String? idToken = await _firebaseAuthRepository.getIdToken();
      
      if (idToken == null) {
        throw 'Failed to get Firebase ID token';
      }
      
      // After successful OTP verification, register the user with your backend
      final authApiRepository = ref.read(authApiRepositoryProvider);

      debugPrint('ID Token: $idToken');

      // Convert XFile to File for mobile, or keep as is for web
      File? profilePhotoFile;
      Uint8List? profilePhotoBytes;
      
      if (kIsWeb) {
        // For web, use the bytes
        profilePhotoBytes = _webImage;
      } else {
        // For mobile, use the file
        if (_pickedImage != null) {
          profilePhotoFile = File(_pickedImage!.path);
        }
      }

      // Create register request with the actual Firebase ID token and profile photo
      final registerRequest = RegisterRequest(
        idToken: idToken,
        fullName: fullName,
        phoneNumber: phoneNumber,
        reraNumber: reraNumber,
        teamLeaderName: teamLeaderName,
        idNumber: idNumber,
        profilePhotoFile: profilePhotoFile, // Include the profile photo file for mobile
        profilePhotoBytes: profilePhotoBytes, // Include the profile photo bytes for web
      );
      
      final result = await authApiRepository.register(registerRequest);
      
      if (result['success']) {
        debugPrint('Registration successful, proceeding to verify token');
        
        // After successful registration, call verifyToken to get access token
        final loginTokenRequest = LoginTokenRequest(idToken: idToken);
        debugPrint('Calling verifyToken with ID token: $idToken');
        
        final tokenResult = await authApiRepository.verifyToken(loginTokenRequest);
        debugPrint('Token verification result: $tokenResult');
        
        if (tokenResult['success']) {
          // Save the access token (assuming it's in the response data)
          // The access token should be saved in secure storage by the API client
          debugPrint('Token verification successful, navigating to dashboard');
          
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration and login successful'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to dashboard
          context.go(Routes.dashboardScreen);
        } else {
          debugPrint('Token verification failed: ${tokenResult['message']}');
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${tokenResult['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        debugPrint('Registration failed: ${result['message']}');
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget submitButton(){
    return CustomButton(
      onPressed: _isLoading 
        ? null 
        : () {
            if(showOtpField) {
              _verifyOTPAndRegister();
            } else {
              _sendOTP();
            }
          },
      text: _isLoading 
        ? 'Processing...' 
        : (showOtpField ? 'Register' : 'Request OTP'),
      height: 52,
      fontSize: 18,
      leadingWidget: _isLoading 
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          )
        : Image.asset(IconsAssets.send, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Responsive.isMobile(context) ? Colors.white : Colors.grey[50],
      body: SafeArea(
        child: Responsive(
          mobile: _buildMobileLayout(),
          tablet: _buildTabletDesktopLayout(),
          desktop: _buildTabletDesktopLayout(),
        ),
      ),
    );
  }
}