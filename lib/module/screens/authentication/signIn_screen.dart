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
import '../../utils/app_fonts.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    _checkAuthState();
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

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    return null;
  }

  Widget _buildMobileLayout() {
    final authState = ref.watch(authControllerProvider);

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
              CustomTextField(
                controller: _phoneController,
                titleText: 'Phone number',
                hintText: 'Enter your phone number (e.g., 1234567890)',
                borderRadius: 6,
                contentSpace: 5,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                enabled: !authState.isOtpSent,
                validator: _validatePhoneNumber,
              ),

              if(authState.isOtpSent)...[
                SizedBox(height: 15),
                CustomTextField(
                  controller: _otpController,
                  titleText: 'OTP',
                  hintText: 'Enter 6-digit OTP',
                  borderRadius: 8,
                  contentSpace: 5,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  validator: _validateOTP,
                ),

                // Resend OTP option
                SizedBox(height: 10),
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
                      onTap: authState.isLoading ? null : () {
                        ref.read(authControllerProvider.notifier).resendOTP();
                        _showSuccessSnackBar('OTP sent again!');
                      },
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: authState.isLoading ? Colors.grey : AppColors.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 30),
              submitButton(),
              SizedBox(height: 30),
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
          ),
        ),
      ),
    );
  }

  Widget _buildTabletDesktopLayout() {
    final authState = ref.watch(authControllerProvider);
    
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
                Image.asset(
                  ImageAssets.highFlyLogo,
                  width: Responsive.isDesktop(context) ? 120 : 100,
                ),
                SizedBox(height: 40),
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
                SizedBox(height: 40),
                CustomTextField(
                  controller: _phoneController,
                  titleText: 'Phone number',
                  hintText: 'Enter your phone number (e.g., +1234567890)',
                  borderRadius: 8,
                  contentSpace: 12,
                  maxLength: 15,
                  keyboardType: TextInputType.phone,
                  enabled: !authState.isOtpSent,
                  validator: _validatePhoneNumber,
                ),

                if(authState.isOtpSent)...[
                  SizedBox(height: 15),
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
                        onTap: authState.isLoading ? null : () {
                          ref.read(authControllerProvider.notifier).resendOTP();
                          _showSuccessSnackBar('OTP sent again!');
                        },
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            color: authState.isLoading ? Colors.grey : AppColors.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 40),
                submitButton(),
                SizedBox(height: 30),
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
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes for errors
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        _showErrorSnackBar(next.error!);
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
                mobile: _buildMobileLayout(),
                tablet: _buildTabletDesktopLayout(),
                desktop: _buildTabletDesktopLayout(),
              ),
      ),
    );
  }


  Widget submitButton() {
    final authState = ref.watch(authControllerProvider);

    return CustomButton(
      onPressed: authState.isLoading ? null : () async {

        if (!_formKey.currentState!.validate()) {
          return;
        }

        try {
          if (!authState.isOtpSent) {
            // Send OTP
            final phoneNumber = "+91${_phoneController.text.trim()}";
            await ref.read(authControllerProvider.notifier).sendOTP(phoneNumber);

            if (authState.isOtpSent) {
              _showSuccessSnackBar('OTP sent to $phoneNumber');
            }
          } else {
            // Verify OTP
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
            }
          }
        } catch (e) {
          debugPrint('Error in submit button: $e'); // Use debugPrint instead of print
          if (context.mounted) {
            _showErrorSnackBar('An error occurred. Please try again.');
          }
        }
      },
      text: authState.isLoading
          ? 'Loading...'
          : (authState.isOtpSent ? 'Verify OTP' : 'Request OTP'),
      height: 52,
      fontSize: 18,
      leadingWidget: authState.isLoading
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