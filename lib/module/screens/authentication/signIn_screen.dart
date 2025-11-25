import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/routes.dart';
import 'package:highfly/module/global/widgets/custom_button.dart';
import 'package:highfly/module/utils/responsive.dart';
import 'package:highfly/module/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../config/constant/app_strings.dart';
import '../../../config/constant/const_assets.dart';
import '../../global/widgets/custom_text_field.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/organization_logo.dart';
import 'otp_verification_screen.dart';
import '../../../data/repository/auth_api_repository_provider.dart';

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
    // Reset auth state after first frame to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authControllerProvider.notifier).reset();
      }
    });
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


  Widget _buildMobileLayout({
    required String heading,
    required String subheading,
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
              SizedBox(height: 30),
              // GestureDetector(
              //   onTap: () {
              //     context.push(Routes.signUp);
              //   },
              //   child: Text(
              //     'Need an account? Sign Up',
              //     style: AppFonts.getFont(
              //       weight: FontWeight.w500,
              //       fontSize: 16,
              //       color: AppColors.secondaryTextColor,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletDesktopLayout({
    required String heading,
    required String subheading,
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
                  width: Responsive.isDesktop(context) ? 140 : 110,
                  height: Responsive.isDesktop(context) ? 140 : 110,
                ),
                const SizedBox(height: 32),
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: Responsive.isDesktop(context) ? 36 : 32,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
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
                // SizedBox(height: 30),
                // GestureDetector(
                //   onTap: () {
                //     context.push(Routes.signUp);
                //   },
                //   child: Text(
                //     'Need an account? Sign Up',
                //     style: AppFonts.getFont(
                //       weight: FontWeight.w500,
                //       fontSize: 16,
                //       color: AppColors.secondaryTextColor,
                //     ),
                //   ),
                // ),
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
    final heading = "";//'${organizationName.toUpperCase()} VISITS';
    final subheading =
        'Sign in to access your $organizationName real estate management dashboard';

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
                ),
                tablet: _buildTabletDesktopLayout(
                  heading: heading,
                  subheading: subheading,
                ),
                desktop: _buildTabletDesktopLayout(
                  heading: heading,
                  subheading: subheading,
                ),
              ),
      ),
    );
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
          final verifyResponse = await ref
              .read(authApiRepositoryProvider)
              .verifyPhoneNumber(rawPhoneNumber);

          final apiSuccess = verifyResponse['success'] == true;
          final apiData = verifyResponse['data'];
          final existsValue = (apiData is Map
                  ? apiData['exists']
                  : null)
              ?.toString()
              .toLowerCase();
          final apiMessage = (apiData is Map
                  ? apiData['message']
                  : verifyResponse['message'])
              ?.toString();

          if (!apiSuccess || existsValue != 'yes') {
            final message = apiMessage?.isNotEmpty == true
                ? apiMessage!
                : 'Phone number not registered';
            if (mounted) {
              _showErrorSnackBar(message);
            }
            return;
          }
        } catch (e) {
          debugPrint('Error verifying phone number: $e');
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