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

  @override
  void initState() {
    super.initState();
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      print('🔥 Image Picker: Attempting to pick image from camera');
      
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      
      print('🔥 Image Picker: Camera result: ${pickedImage != null ? 'Image captured' : 'No image captured'}');
      
      if (pickedImage != null) {
        print('🔥 Image Picker: Processing captured image');
        
        if (kIsWeb) {
          print('🔥 Image Picker: Web platform detected');
          // For web, we need to read the image as bytes
          final bytes = await pickedImage.readAsBytes();
          print('🔥 Image Picker: Image bytes length: ${bytes.length}');
          
          setState(() {
            _webImage = bytes;
            _pickedImage = pickedImage;
          });
          
          print('🔥 Image Picker: Web image state updated');
        } else {
          print('🔥 Image Picker: Mobile platform detected');
          // For mobile, we can use the file directly
          setState(() {
            _pickedImage = pickedImage;
          });
          
          print('🔥 Image Picker: Mobile image state updated');
        }
      } else {
        print('🔥 Image Picker: No image was captured');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image captured', style: TextStyle(color: Colors.white)),
              backgroundColor:  AppColors.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      print('🔥 Image Picker: Error picking image from camera: $e');
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

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      print('🔥 Image Picker: Attempting to pick image from gallery');
      
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      print('🔥 Image Picker: Gallery result: ${pickedImage != null ? 'Image selected' : 'No image selected'}');
      
      if (pickedImage != null) {
        print('🔥 Image Picker: Processing selected image');
        
        if (kIsWeb) {
          print('🔥 Image Picker: Web platform detected');
          // For web, we need to read the image as bytes
          final bytes = await pickedImage.readAsBytes();
          print('🔥 Image Picker: Image bytes length: ${bytes.length}');
          
          setState(() {
            _webImage = bytes;
            _pickedImage = pickedImage;
          });
          
          print('🔥 Image Picker: Web image state updated');
        } else {
          print('🔥 Image Picker: Mobile platform detected');
          // For mobile, we can use the file directly
          setState(() {
            _pickedImage = pickedImage;
          });
          
          print('🔥 Image Picker: Mobile image state updated');
        }
      } else {
        print('🔥 Image Picker: No image was selected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              backgroundColor:  AppColors.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      print('🔥 Image Picker: Error picking image from gallery: $e');
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

  /// Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    if (kIsWeb) {
      // On web, show a simple dialog with gallery option only
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

  /// Clear the selected image
  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _webImage = null;
    });
    print('🔥 Image Picker: Image cleared');
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
              radius: const Radius.circular(50),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              color: AppColors.buttonBorderColor,
            ),
            child: Container(
              height: 90,
              width: 90,
              decoration: const BoxDecoration(
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
                                    return const Icon(Icons.error, color: Colors.red);
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
                                    return const Icon(Icons.error, color: Colors.red);
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
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            color: AppColors.buttonBorderColor,
                          ),
                          child: const Icon(
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
            // const SizedBox(height: 30),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 30.0),
            //   child: Text(
            //     SignInScreenString.heading1,
            //     style: TextStyle(
            //       fontSize: 30,
            //       fontWeight: FontWeight.w500,
            //       color: Colors.black,
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            _buildProfilePhotoSection(),
            const SizedBox(height: 20),
            CustomTextField(
              titleText: 'Full Name',
              hintText: 'Enter your full name',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 13,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              titleText: 'Phone Number',
              hintText: '+123456789',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 13,
            ),

            if(showOtpField)...[
              const SizedBox(height: 20),
              CustomTextField(
                titleText: 'OTP',
                hintText: 'Enter 6-digit OTP',
                borderRadius: 6,
                contentSpace: 8,
                maxLength: 13,
              ),
            ],

            const SizedBox(height: 20),
            CustomTextField(
              titleText: 'RERA Number',
              hintText: 'Enter your RERA number',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 13,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              titleText: 'ID Number',
              hintText: 'Enter your ID number',
              borderRadius: 6,
              contentSpace: 8,
              maxLength: 13,
            ),
            const SizedBox(height: 30),

            submitButton(),

            const SizedBox(height: 30),

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

            const SizedBox(height: 30)
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
          margin: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 20,
          ),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
              // const SizedBox(height: 30),
              // Text(
              //   SignInScreenString.heading1,
              //   style: TextStyle(
              //     fontSize: Responsive.isDesktop(context) ? 36 : 32,
              //     fontWeight: FontWeight.w500,
              //     color: Colors.black,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              // const SizedBox(height: 16),
              Text(
                SignInScreenString.heading2,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _buildProfilePhotoSection(),
              const SizedBox(height: 30),
              // Two-column layout for desktop, single column for tablet
              if (Responsive.isDesktop(context))
                _buildDesktopFormFields()
              else
                _buildTabletFormFields(),
              const SizedBox(height: 40),

              submitButton(),

              const SizedBox(height: 30),
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
                titleText: 'Full Name',
                hintText: 'Enter your full name',
                borderRadius: 8,
                contentSpace: 12,
                maxLength: 13,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: CustomTextField(
                titleText: 'Phone Number',
                hintText: '+123456789',
                borderRadius: 8,
                contentSpace: 12,
                maxLength: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [

            if(showOtpField)...[
              Expanded(
                child: CustomTextField(
                  titleText: 'OTP',
                  hintText: 'Enter 6-digit OTP',
                  borderRadius: 8,
                  contentSpace: 12,
                  maxLength: 13,
                ),
              ),
              const SizedBox(width: 20),
            ],

            Expanded(
              child: CustomTextField(
                titleText: 'RERA Number',
                hintText: 'Enter your RERA number',
                borderRadius: 8,
                contentSpace: 12,
                maxLength: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomTextField(
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
          titleText: 'Full Name',
          hintText: 'Enter your full name',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 13,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          titleText: 'Phone Number',
          hintText: '+123456789',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 13,
        ),

        if(showOtpField)...[
          const SizedBox(height: 20),
          CustomTextField(
            titleText: 'OTP',
            hintText: 'Enter 6-digit OTP',
            borderRadius: 8,
            contentSpace: 12,
            maxLength: 13,
          ),
        ],

        const SizedBox(height: 20),
        CustomTextField(
          titleText: 'RERA Number',
          hintText: 'Enter your RERA number',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 13,
        ),
        const SizedBox(height: 20),
        CustomTextField(
          titleText: 'ID Number',
          hintText: 'Enter your ID number',
          borderRadius: 8,
          contentSpace: 12,
          maxLength: 13,
        ),
      ],
    );
  }

  Widget submitButton(){
    return CustomButton(
      onPressed: (){
        if(showOtpField){
          context.go(Routes.dashboardScreen);
        } else {
          setState(() {
            showOtpField = !showOtpField;
          });
        }
      },
      text: showOtpField ? 'Verify OTP' : 'Request OTP',
      height: 52,
      fontSize: 18,
      leadingWidget: Image.asset(IconsAssets.send, color: Colors.white),
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