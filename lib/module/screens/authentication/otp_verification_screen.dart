import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/routes.dart';
import 'package:highfly/module/global/widgets/custom_button.dart';
import 'package:highfly/module/utils/responsive.dart';
import 'package:highfly/module/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show File;
import 'dart:typed_data' show Uint8List;
import 'dart:async' show Timer;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../config/constant/app_strings.dart';
import '../../../config/constant/const_assets.dart';
import '../../global/widgets/custom_text_field.dart';
import '../../utils/app_fonts.dart';
import 'package:highfly/data/repository/auth_api_repository_provider.dart';
import 'package:highfly/data/models/request_models/auth_request_model.dart';
import 'package:highfly/data/repository/firebase_auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/analytics_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/organization_logo.dart';

enum OtpScreenType { signIn, signUp }

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final OtpScreenType type;
  // Sign up data (only used when type is signUp)
  final String? fullName;
  final String? reraNumber;
  final String? teamLeaderName;
  final String? idNumber;
  final XFile? profilePhoto;
  final Uint8List? profilePhotoBytes;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.type,
    this.fullName,
    this.reraNumber,
    this.teamLeaderName,
    this.idNumber,
    this.profilePhoto,
    this.profilePhotoBytes,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // For verify OTP action
  bool _isResending = false; // For resend OTP action
  String? _errorMessage;
  late String _verificationId; // Store verification ID in state so it can be updated on resend
  
  // Firebase auth repository
  final FirebaseAuthRepository _firebaseAuthRepository = FirebaseAuthRepository();
  
  // Secure storage for cleanup
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  /// Clean up Firebase auth and secure storage when registration fails
  Future<void> _cleanupOnRegistrationFailure() async {
    try {
      debugPrint('🧹 Cleaning up Firebase auth and secure storage due to registration failure');
      
      // Sign out from Firebase
      await _firebaseAuthRepository.signOut();
      
      // Clear all secure storage keys
      await _secureStorage.delete(key: SharedPreferenceStrings.accessToken);
      await _secureStorage.delete(key: SharedPreferenceStrings.id);
      await _secureStorage.delete(key: SharedPreferenceStrings.firstName);
      await _secureStorage.delete(key: SharedPreferenceStrings.fullName);
      await _secureStorage.delete(key: SharedPreferenceStrings.phoneNumber);
      await _secureStorage.delete(key: SharedPreferenceStrings.profilePhoto);
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'user_data');
      
      debugPrint('✅ Cleanup completed successfully');
    } catch (e) {
      debugPrint('⚠️ Error during cleanup: $e');
    }
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    // Prevent multiple simultaneous requests
    if (_isResending || _isLoading) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    // Add a timeout safety mechanism (65 seconds - slightly longer than Firebase's 60s timeout)
    Timer? timeoutTimer;
    bool hasCompleted = false;

    void completeResend() {
      if (!hasCompleted) {
        hasCompleted = true;
        timeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _isResending = false;
          });
        }
      }
    }

    try {
      debugPrint('🔄 Resending OTP to ${widget.phoneNumber}');
      
      // Set up timeout safety
      timeoutTimer = Timer(const Duration(seconds: 65), () {
        if (!hasCompleted) {
          debugPrint('⚠️ Resend OTP timeout - completing operation');
          completeResend();
          if (mounted) {
            _showErrorSnackBar('OTP resend timed out. Please try again.');
          }
        }
      });

      await _firebaseAuthRepository.sendOTP(
        phoneNumber: widget.phoneNumber,
        onCodeSent: (verificationId) {
          debugPrint('✅ OTP resent successfully. New verification ID: $verificationId');
          if (!hasCompleted) {
            completeResend();
            if (mounted) {
              setState(() {
                _verificationId = verificationId; // Update verification ID
                _errorMessage = null; // Clear any previous errors
              });
              _showSuccessSnackBar('OTP sent again!');
            }
          }
        },
        onError: (error) {
          debugPrint('❌ Error resending OTP: $error');
          if (!hasCompleted) {
            completeResend();
            if (mounted) {
              _showErrorSnackBar(error);
            }
          }
        },
        onAutoVerificationCompleted: () {
          debugPrint('✅ Auto-verification completed on resend');
          // Don't complete here - wait for onCodeSent
        },
      );
    } catch (e) {
      debugPrint('❌ Exception while resending OTP: $e');
      if (!hasCompleted) {
        completeResend();
        if (mounted) {
          _showErrorSnackBar('Failed to resend OTP: ${e.toString()}');
        }
      }
    }
  }

  // Verify OTP for Sign In
  Future<void> _verifyOTPForSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpCode = _otpController.text.trim();
      final success = await ref.read(authControllerProvider.notifier).verifyOTP(otpCode);

      if (success && context.mounted) {
        _showSuccessSnackBar('Login successful!');
        // Navigate to dashboard after short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            context.go(Routes.dashboardScreen);
          }
        });
      } else {
        // Wrong OTP - show error on same page
        final authState = ref.read(authControllerProvider);
        setState(() {
          _isLoading = false;
          _errorMessage = authState.error ?? 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      
      // Check if this is an OTP verification error
      final isOtpError = errorString.contains('invalid') && 
                        (errorString.contains('verification') || 
                         errorString.contains('code') ||
                         errorString.contains('otp')) ||
                        errorString.contains('verification code') ||
                        errorString.contains('verification failed') ||
                        errorString.contains('session-expired') ||
                        errorString.contains('session expired');
      
      if (isOtpError) {
        // Wrong OTP - show error on same page
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
        });
      } else {
        // Other error
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
        _showErrorSnackBar('An error occurred. Please try again.');
      }
    }
  }

  // Verify OTP and Register for Sign Up
  Future<void> _verifyOTPAndRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate sign up data
    if (widget.type == OtpScreenType.signUp) {
      if (widget.fullName == null || widget.fullName!.isEmpty) {
        _showErrorSnackBar('Missing required information. Please go back and fill all fields.');
        return;
      }
      if (widget.profilePhoto == null && widget.profilePhotoBytes == null) {
        _showErrorSnackBar('Missing profile photo. Please go back and select a photo.');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final otpCode = _otpController.text.trim();
      
      // First, verify the OTP with Firebase
      await _firebaseAuthRepository.verifyOTP(
        otpCode: otpCode,
        verificationId: _verificationId,
      );
      
      // Get the Firebase ID token
      final String? idToken = await _firebaseAuthRepository.getIdToken();
      
      if (idToken == null) {
        throw 'Failed to get Firebase ID token';
      }
      
      // After successful OTP verification, register the user with backend
      final authApiRepository = ref.read(authApiRepositoryProvider);

      debugPrint('ID Token: $idToken');

      // Convert XFile to File for mobile, or keep as is for web
      File? profilePhotoFile;
      Uint8List? profilePhotoBytes;
      
      if (kIsWeb) {
        // For web, use the bytes
        profilePhotoBytes = widget.profilePhotoBytes;
      } else {
        // For mobile, use the file
        if (widget.profilePhoto != null) {
          profilePhotoFile = File(widget.profilePhoto!.path);
        }
      }

      // Create register request
      final registerRequest = RegisterRequest(
        idToken: idToken,
        fullName: widget.fullName!,
        phoneNumber: widget.phoneNumber,
        reraNumber: widget.reraNumber ?? '',
        teamLeaderName: widget.teamLeaderName ?? '',
        idNumber: widget.idNumber ?? '',
        profilePhotoFile: profilePhotoFile,
        profilePhotoBytes: profilePhotoBytes,
      );
      
      final result = await authApiRepository.register(registerRequest);
      
      if (result['success']) {
        debugPrint('Registration successful, proceeding to verify token');
        
        // After successful registration, call verifyToken to get access token
        final loginTokenRequest = LoginTokenRequest(
          idToken: idToken,
          phoneNumber: widget.phoneNumber,
        );
        debugPrint('Calling verifyToken with ID token: $idToken');
        
        final tokenResult = await authApiRepository.verifyToken(loginTokenRequest);
        debugPrint('Token verification result: $tokenResult');
        
        if (tokenResult['success']) {
          // Save user data to secure storage
          final data = tokenResult['data'];
          if (data != null && data is Map) {
            final accessToken = data['access_token']?.toString() ?? '';
            final agent = data['agent'];
            if (agent != null && agent is Map) {
              final id = agent['id']?.toString() ?? '';
              final fName = agent['full_name']?.toString() ?? '';
              final fullName = agent['full_name']?.toString() ?? '';
              final user = agent['user'];
              final phoneNumber = (user != null && user is Map) ? (user['phone_number']?.toString() ?? '') : '';
              final profileImage = (user != null && user is Map) ? (user['profile_image']?.toString() ?? '') : '';
              
              if (accessToken.isNotEmpty) {
                await _secureStorage.write(key: SharedPreferenceStrings.accessToken, value: accessToken);
              }
              if (id.isNotEmpty) {
                await _secureStorage.write(key: SharedPreferenceStrings.id, value: id);
              }
              if (fName.isNotEmpty) {
                await _secureStorage.write(key: SharedPreferenceStrings.firstName, value: fName);
              }
              if (fullName.isNotEmpty) {
                await _secureStorage.write(key: SharedPreferenceStrings.fullName, value: fullName);
              }
              if (phoneNumber.isNotEmpty) {
                await _secureStorage.write(key: SharedPreferenceStrings.phoneNumber, value: phoneNumber);
              }
              if (profileImage.isNotEmpty) {
                final profilePhotoUrl = "${dotenv.env['BASE_URL_IMAGE']}$profileImage";
                await _secureStorage.write(key: SharedPreferenceStrings.profilePhoto, value: profilePhotoUrl);
              }
              
              debugPrint('Token verification successful, user data saved to secure storage');
            }
          }
          
          // Log analytics event for successful signup
          try {
            final analyticsService = ref.read(analyticsProvider);
            await analyticsService.logSignUp(method: 'phone_otp');
            if (tokenResult['data'] != null && tokenResult['data']['agent'] != null) {
              final id = tokenResult['data']['agent']['id']?.toString();
              if (id != null) {
                await analyticsService.setUserId(id);
              }
            }
          } catch (e) {
            debugPrint('Error logging signup analytics: $e');
          }
          
          setState(() {
            _isLoading = false;
          });
          
          _showSuccessSnackBar('Registration and login successful');
          
          // Navigate to dashboard
          context.go(Routes.dashboardScreen);
        } else {
          debugPrint('Token verification failed: ${tokenResult['message']}');
          setState(() {
            _isLoading = false;
          });
          
          // Other error - go back to sign up screen
          _showErrorSnackBar('Login failed: ${tokenResult['message']}');
          Future.delayed(const Duration(seconds: 2), () {
            if (context.mounted) {
              context.pop();
            }
          });
        }
      } else {
        debugPrint('Registration failed: ${result['message']}');
        
        // Clean up Firebase auth and secure storage since registration failed
        await _cleanupOnRegistrationFailure();
        
        setState(() {
          _isLoading = false;
        });
        
        // Other error - go back to sign up screen
        _showErrorSnackBar('Registration failed: ${result['message']}');
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            context.pop();
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase auth errors (wrong OTP, etc.)
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The verification code entered is invalid.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'The verification ID is invalid.';
          break;
        case 'session-expired':
          errorMessage = 'The verification session has expired. Please request a new OTP.';
          break;
        default:
          errorMessage = 'Verification failed: ${e.message}';
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage; // Show error on same page for wrong OTP
      });
    } catch (e) {
      debugPrint('Registration error: $e');
      
      final errorString = e.toString().toLowerCase();
      
      // Check if this is an OTP verification error (wrong OTP, invalid code, etc.)
      // These errors should be shown on the same page, not navigate back
      final isOtpError = errorString.contains('invalid') && 
                        (errorString.contains('verification') || 
                         errorString.contains('code') ||
                         errorString.contains('otp')) ||
                        errorString.contains('verification code') ||
                        errorString.contains('verification failed') ||
                        errorString.contains('session-expired') ||
                        errorString.contains('session expired');
      
      if (isOtpError) {
        // Wrong OTP or OTP-related error - show on same page
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('Error: ', '');
        });
      } else {
        // Other error (registration failure, network error, etc.) - go back to sign up screen
        // Clean up Firebase auth and secure storage since registration failed
        await _cleanupOnRegistrationFailure();
        
        setState(() {
          _isLoading = false;
        });
        
        _showErrorSnackBar('Registration failed: ${e.toString()}');
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            context.pop();
          }
        });
      }
    }
  }

  Widget _buildMobileLayout(String organizationName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: OrganizationLogo(
                  width: 220,
                  height: 140,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                organizationName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'We sent a verification code to\n${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 40),
              CustomTextField(
                controller: _otpController,
                titleText: 'OTP',
                hintText: 'Enter 6-digit OTP',
                borderRadius: 6,
                contentSpace: 5,
                maxLength: 6,
                keyboardType: TextInputType.number,
                validator: _validateOTP,
              ),
              
              if (_errorMessage != null) ...[
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Resend OTP option
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive OTP? ",
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: (_isResending || _isLoading) ? null : _resendOTP,
                    child: Text(
                      _isResending ? 'Sending...' : 'Resend',
                      style: TextStyle(
                        color: (_isResending || _isLoading) ? Colors.grey : AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),
              CustomButton(
                onPressed: _isLoading ? null : () {
                  if (widget.type == OtpScreenType.signIn) {
                    _verifyOTPForSignIn();
                  } else {
                    _verifyOTPAndRegister();
                  }
                },
                text: _isLoading
                    ? 'Verifying...'
                    : (widget.type == OtpScreenType.signIn ? 'Verify OTP' : 'Register'),
                height: 52,
                fontSize: 18,
                leadingWidget: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Image.asset(IconsAssets.send, color: Colors.white),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  context.pop();
                },
                child: Text(
                  'Change Phone Number',
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

  Widget _buildTabletDesktopLayout(String organizationName) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 500 : 400,
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                OrganizationLogo(
                  width: Responsive.isDesktop(context)  ? 240 : 110,
                  height: Responsive.isDesktop(context) ? 240 : 110,
                ),
                const SizedBox(height: 5),
                // Text(
                //   organizationName,
                //   style: const TextStyle(
                //     fontSize: 20,
                //     fontWeight: FontWeight.w600,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                // const SizedBox(height: 24),
                Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: Responsive.isDesktop(context) ? 32 : 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'We sent a verification code to\n${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                CustomTextField(
                  controller: _otpController,
                  titleText: 'OTP',
                  hintText: 'Enter 6-digit OTP',
                  borderRadius: 8,
                  contentSpace: 12,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  validator: _validateOTP,
                ),
                
                if (_errorMessage != null) ...[
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Resend OTP option
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive OTP? ",
                      style: TextStyle(
                        color: AppColors.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: (_isResending || _isLoading) ? null : _resendOTP,
                      child: Text(
                        _isResending ? 'Sending...' : 'Resend',
                        style: TextStyle(
                          color: (_isResending || _isLoading) ? Colors.grey : AppColors.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40),
                CustomButton(
                  onPressed: _isLoading ? null : () {
                    if (widget.type == OtpScreenType.signIn) {
                      _verifyOTPForSignIn();
                    } else {
                      _verifyOTPAndRegister();
                    }
                  },
                  text: _isLoading
                      ? 'Verifying...'
                      : (widget.type == OtpScreenType.signIn ? 'Verify OTP' : 'Register'),
                  height: 52,
                  fontSize: 18,
                  leadingWidget: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Image.asset(IconsAssets.send, color: Colors.white),
                ),
                SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    context.pop();
                  },
                  child: Text(
                    'Change Phone Number',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizationState = ref.watch(organizationProvider);
    final organizationName =
        organizationState.asData?.value?.name ?? GlobalStrings.appName;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Responsive(
          mobile: _buildMobileLayout(organizationName),
          tablet: _buildTabletDesktopLayout(organizationName),
          desktop: _buildTabletDesktopLayout(organizationName),
        ),
      ),
    );
  }
}

