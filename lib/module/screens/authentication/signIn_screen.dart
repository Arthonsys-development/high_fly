import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/routes.dart';
import 'package:highfly/module/global/widgets/custom_button.dart';
import 'package:highfly/module/utils/app_fonts.dart';
import 'package:highfly/module/utils/responsive.dart';
import 'package:highfly/module/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../config/constant/app_strings.dart';
import '../../../config/constant/const_assets.dart';
import '../../global/widgets/custom_text_field.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/organization_logo.dart';
import 'otp_verification_screen.dart';
import '../../../data/repository/auth_api_repository_provider.dart';
import '../../../data/models/response_model/organization_response_model.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _pendingPhoneNumber; // Track phone number for navigation
  bool _hasNavigated = false; // Prevent multiple navigations
  bool _isVerifyingPhone = false;
  bool _isGuestLoading = false; // Track guest login loading state
  String? _currentAppVersion; // Store current app version

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    _checkAuthState();
    // Get current app version
    _getCurrentAppVersion();
    // Reset auth state after first frame to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).reset();
      }
    });
  }

  /// Get current app version
  Future<void> _getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentAppVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error getting app version: $e');
    }
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is already signed in, navigate to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(Routes.dashboardScreen);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Basic phone number validation
    // final phoneRegex = RegExp(r'^\d{1,10}$');
    // if (!phoneRegex.hasMatch(value)) {
    //   return 'Please enter a valid phone number (e.g., 1234567890)';
    // }
    return null; // Add explicit return
  }

  /// Convert version string to number (e.g., "1.0.3" → 103)
  int _versionToNumber(String version) {
    try {
      final parts = version.split('.');
      if (parts.length >= 3) {
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        final patch = int.parse(parts[2]);
        return (major * 100) + (minor * 10) + patch;
      }
      return 0;
    } catch (e) {
      debugPrint('Error converting version to number: $e');
      return 0;
    }
  }

  /// Check if signup should be shown based on version and API flag
  bool _shouldShowSignup(Organization? organization) {
    // First check if showSignup is true in API
    final apiShowSignup = organization?.showSignup ?? false;
    
    if (!apiShowSignup) {
      return false; // If API says don't show, respect that
    }

    // If no app version info from API, show signup (default behavior)
    if (organization?.appUpdate == null || _currentAppVersion == null) {
      return true;
    }

    // Get API version based on platform
    String? apiVersion;
    if (kIsWeb) {
      return true; // For web, always show if API flag is true
    } else if (Platform.isIOS) {
      apiVersion = organization?.appUpdate?.ios?.version;
    } else if (Platform.isAndroid) {
      apiVersion = organization?.appUpdate?.android?.version;
    }

    // If no API version for this platform, show signup
    if (apiVersion == null) {
      return true;
    }

    // Convert versions to numbers and compare
    final currentVersionNumber = _versionToNumber(_currentAppVersion!);
    final apiVersionNumber = _versionToNumber(apiVersion);

    debugPrint('📱 Signup Visibility Check:');
    debugPrint('  API showSignup flag: $apiShowSignup');
    debugPrint('  Current Version: $_currentAppVersion ($currentVersionNumber)');
    debugPrint('  API Version: $apiVersion ($apiVersionNumber)');
    debugPrint('  Current > API: ${currentVersionNumber > apiVersionNumber}');

    // Show signup if current version is greater than API version AND showSignup is true
    return currentVersionNumber > apiVersionNumber && apiShowSignup;
  }


  Widget _buildMobileLayout({
    required String heading,
    required String subheading,
    required bool showSignup,
  }) {
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
                  width: 250,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
             /* Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12), */
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  subheading,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 40),
              CustomTextField(
                controller: _phoneController,
                titleText: 'Phone number',
                hintText: 'Enter your phone number (e.g., 1234567890)',
                borderRadius: 6,
                contentSpace: 5,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                validator: _validatePhoneNumber,
              ),

              SizedBox(height: 30),
              submitButton(),
              if (showSignup) ...[
                SizedBox(height: 30),
                _buildOrDivider(),
                SizedBox(height: 20),
                _buildGuestLoginButton(),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    context.push(Routes.signUp);
                  },
                  child: Text(
                    'Need an account? Sign Up',
                    style: AppFonts.getFont(
                      weight: FontWeight.w500,
                      fontSize: 16,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletDesktopLayout({
    required String heading,
    required String subheading,
    required bool showSignup,
  }) {
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
                color: Colors.black.withValues(alpha: 0.1),
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
                  width: Responsive.isDesktop(context) ? 240 : 110,
                  height: Responsive.isDesktop(context) ? 240 : 110,
                ),
                const SizedBox(height: 5),
                // Text(
                //   heading,
                //   style: TextStyle(
                //     fontSize: Responsive.isDesktop(context) ? 36 : 32,
                //     fontWeight: FontWeight.w500,
                //     color: Colors.black,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                // const SizedBox(height: 16),
                Text(
                  subheading,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                CustomTextField(
                  controller: _phoneController,
                  titleText: 'Phone number',
                  hintText: 'Enter your phone number (e.g., +1234567890)',
                  borderRadius: 8,
                  contentSpace: 12,
                  maxLength: 10,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhoneNumber,
                ),

                SizedBox(height: 40),
                submitButton(),
                if (showSignup) ...[
                  SizedBox(height: 30),
                  _buildOrDivider(),
                  SizedBox(height: 20),
                  _buildGuestLoginButton(),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      context.push(Routes.signUp);
                    },
                    child: Text(
                      'Need an account? Sign Up',
                      style: AppFonts.getFont(
                        weight: FontWeight.w500,
                        fontSize: 16,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
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
    final organization = organizationState.asData?.value;
    final organizationName =
        organization?.name ?? GlobalStrings.appName;
    final heading = "";//'${organizationName.toUpperCase()} VISITS';
    final subheading =
        'Sign in to access your $organizationName real estate management dashboard';
    final showSignup = _shouldShowSignup(organization);

    // Listen to auth state changes for errors and navigation
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        _showErrorSnackBar(next.error!);
      }
      
      // Navigate to OTP screen when OTP is sent successfully
      if (next.isOtpSent && 
          next.verificationId != null && 
          _pendingPhoneNumber != null && 
          !_hasNavigated &&
          context.mounted) {
        _hasNavigated = true;
        final phoneNumber = _pendingPhoneNumber!;
        final verificationId = next.verificationId!;
        
        _showSuccessSnackBar('OTP sent to $phoneNumber');
        
        // Navigate to OTP screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            context.push(
              Routes.otp,
              extra: {
                'phoneNumber': phoneNumber,
                'verificationId': verificationId,
                'type': OtpScreenType.signIn,
              },
            );
            // Reset flags after navigation
            _pendingPhoneNumber = null;
            _hasNavigated = false;
          }
        });
      }
    });
    
    return Scaffold(
      backgroundColor: Colors.white, // Same background for both platforms
      body: SafeArea(
        child: /*kIsWeb
          ? Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: const WebPhoneAuthWidget(),
                ),
              ),
            )
          : */Responsive(
                mobile: _buildMobileLayout(
                  heading: heading,
                  subheading: subheading,
                  showSignup: showSignup,
                ),
                tablet: _buildTabletDesktopLayout(
                  heading: heading,
                  subheading: subheading,
                  showSignup: showSignup,
                ),
                desktop: _buildTabletDesktopLayout(
                  heading: heading,
                  subheading: subheading,
                  showSignup: showSignup,
                ),
              ),
      ),
    );
  }


  // OR Divider
  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'OR',
            style: AppFonts.getFont(
              weight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  // Guest Login Button
  Widget _buildGuestLoginButton() {
    final authState = ref.watch(authControllerProvider);
    final isProcessing = authState.isLoading || _isVerifyingPhone || _isGuestLoading;

    return CustomButton(
      onPressed: isProcessing ? null : _handleGuestLogin,
      text: _isGuestLoading ? 'Signing in as Guest...' : 'Continue as Guest',
      height: 52,
      fontSize: 18,
      backgroundColor: Colors.grey[700],
      leadingWidget: _isGuestLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.person_outline, color: Colors.white),
    );
  }

  // Handle guest login
  Future<void> _handleGuestLogin() async {
    setState(() {
      _isGuestLoading = true;
    });

    try {
      debugPrint('🎭 Starting guest login flow...');
      final success = await ref.read(authControllerProvider.notifier).signInAsGuest();
      
      if (success && mounted) {
        debugPrint('🎭 Guest login successful, navigating to dashboard...');
        _showSuccessSnackBar('Signed in as Guest');
        
        // Navigate to dashboard
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go(Routes.dashboardScreen);
          }
        });
      } else if (mounted) {
        debugPrint('🎭 Guest login failed');
        final errorMessage = ref.read(authControllerProvider).error ?? 'Guest login failed';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      debugPrint('🎭 Exception during guest login: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to sign in as guest. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  Widget submitButton() {
    final authState = ref.watch(authControllerProvider);
    final isProcessing = authState.isLoading || _isVerifyingPhone;

    return CustomButton(
      onPressed: isProcessing ? null : () async {
        if (!_formKey.currentState!.validate()) {
          return;
        }

        try {
          setState(() {
            _isVerifyingPhone = true;
          });

          final rawPhoneNumber = _phoneController.text.trim();
          debugPrint('🔍 Verifying phone number: $rawPhoneNumber');
          final verifyResponse = await ref
              .read(authApiRepositoryProvider)
              .verifyPhoneNumber(rawPhoneNumber);

          debugPrint('📱 Verify phone response: $verifyResponse');
          
          final apiSuccess = verifyResponse['success'] == true;
          final apiData = verifyResponse['data'];
          debugPrint('📱 API Success: $apiSuccess');
          debugPrint('📱 API Data: $apiData');
          debugPrint('📱 API Data type: ${apiData.runtimeType}');
          
          // Handle different response formats
          String? existsValue;
          if (apiData is Map) {
            // Try different possible field names and formats
            final exists = apiData['exists'];
            debugPrint('📱 Exists field value: $exists (type: ${exists.runtimeType})');
            
            if (exists != null) {
              // Handle boolean, string, or number
              if (exists is bool) {
                existsValue = exists ? 'yes' : 'no';
              } else {
                existsValue = exists.toString().toLowerCase();
              }
            }
          }
          
          debugPrint('📱 Parsed existsValue: $existsValue');
          
          final apiMessage = (apiData is Map
                  ? apiData['message']
                  : verifyResponse['message'])
              ?.toString();

          // Check if phone exists - be more flexible with the check
          // If existsValue is null but API succeeded, assume phone exists (server returned 200 OK)
          final phoneExists = existsValue == null 
              ? apiSuccess  // If no exists field but API succeeded, assume it exists
              : (existsValue == 'yes' || existsValue == 'true' || existsValue == '1');
          
          debugPrint('📱 Phone exists check: $phoneExists (existsValue: $existsValue, apiSuccess: $apiSuccess)');
          
          if (!apiSuccess) {
            debugPrint('❌ API call failed: $apiMessage');
            final message = apiMessage?.isNotEmpty == true
                ? apiMessage!
                : 'Phone number verification failed';
            if (mounted) {
              _showErrorSnackBar(message);
            }
            return;
          }
          
          // Only check existsValue if it was provided in the response
          // If API succeeded (200 OK) but no exists field, proceed anyway
          if (existsValue != null && !phoneExists) {
            debugPrint('❌ Phone number not registered (existsValue: $existsValue)');
            final message = apiMessage?.isNotEmpty == true
                ? apiMessage!
                : 'Phone number not registered';
            if (mounted) {
              _showErrorSnackBar(message);
            }
            return;
          }
          
          debugPrint('✅ Phone verification successful, proceeding to send OTP');
        } catch (e, stackTrace) {
          debugPrint('❌ Error verifying phone number: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          if (mounted) {
            _showErrorSnackBar('Unable to verify phone number. Please try again.');
          }
          return;
        } finally {
          if (mounted) {
            setState(() {
              _isVerifyingPhone = false;
            });
          }
        }

        try {
          // Reset navigation flag
          _hasNavigated = false;
          
          // Send OTP
          final phoneNumber = "+91${_phoneController.text.trim()}";
          _pendingPhoneNumber = phoneNumber; // Store phone number for navigation
          
          await ref.read(authControllerProvider.notifier).sendOTP(phoneNumber);
          
          // Navigation will be handled by the ref.listen in build method
          // when the state updates to isOtpSent: true
        } catch (e) {
          debugPrint('Error in submit button: $e');
          _pendingPhoneNumber = null; // Clear pending phone number on error
          if (context.mounted) {
            _showErrorSnackBar('An error occurred. Please try again.');
          }
        }
      },
      text: isProcessing ? 'Loading...' : 'Request OTP',
      height: 52,
      fontSize: 18,
      leadingWidget: isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Image.asset(IconsAssets.send, color: Colors.white),
    );
  }
}