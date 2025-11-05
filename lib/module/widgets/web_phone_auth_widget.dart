import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_colors.dart';
import 'package:highfly/config/routes.dart';
import '../providers/auth_provider.dart';
import '../global/widgets/custom_text_field.dart';
import '../global/widgets/custom_button.dart';
import '../../config/constant/app_strings.dart';
import '../../config/constant/const_assets.dart';
import '../utils/app_fonts.dart';

class WebPhoneAuthWidget extends ConsumerStatefulWidget {
  const WebPhoneAuthWidget({super.key});

  @override
  ConsumerState<WebPhoneAuthWidget> createState() => _WebPhoneAuthWidgetState();
}

class _WebPhoneAuthWidgetState extends ConsumerState<WebPhoneAuthWidget> {
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
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    // Listen to auth state changes for errors
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                ImageAssets.highFlyLogo,
                width: 100,
              ),
            ),
            const SizedBox(height: 30),

            // Main heading
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
            const SizedBox(height: 10),

            // Subtitle
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

            // Phone number input
            CustomTextField(
              controller: _phoneController,
              titleText: 'Phone number',
              hintText: 'Enter your phone number (e.g., +1234567890)',
              borderRadius: 6,
              contentSpace: 5,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              enabled: !authState.isOtpSent,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                // Basic phone number validation
                final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'Please enter a valid phone number with country code (e.g., +1234567890)';
                }
                return null;
              },
            ),

            // OTP input (shown when OTP is sent)
            if (authState.isOtpSent) ...[
              const SizedBox(height: 15),
              CustomTextField(
                controller: _otpController,
                titleText: 'OTP',
                hintText: 'Enter 6-digit OTP',
                borderRadius: 8,
                contentSpace: 5,
                maxLength: 6,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the OTP';
                  }
                  if (value.length != 6) {
                    return 'OTP must be 6 digits';
                  }
                  return null;
                },
              ),

              // Resend OTP option
              const SizedBox(height: 10),
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
                    onTap: authState.isLoading ? null : () async {
                      await authController.sendOTP(_phoneController.text.trim());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('OTP sent again!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
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

            const SizedBox(height: 30),

            // Submit button using CustomButton like mobile
            CustomButton(
              onPressed: authState.isLoading ? null : () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }

                try {
                  if (!authState.isOtpSent) {
                    // Send OTP
                    final phoneNumber = _phoneController.text.trim();
                    await authController.sendOTP(phoneNumber);

                    if (authState.isOtpSent && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('OTP sent to $phoneNumber'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } else {
                    // Verify OTP
                    final otpCode = _otpController.text.trim();
                    final success = await authController.verifyOTP(otpCode);

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Login successful!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      // Navigate to dashboard after short delay
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (context.mounted) {
                          context.go(Routes.dashboardScreen);
                        }
                      });
                    }
                  }
                } catch (e) {
                  print('Error in web auth widget: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('An error occurred. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
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
            ),

            const SizedBox(height: 30),

            // Sign up link
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

            // Web platform indicator (subtle)
            // if (kIsWeb) ...[
            //   const SizedBox(height: 20),
            //   Container(
            //     padding: const EdgeInsets.all(8),
            //     decoration: BoxDecoration(
            //       color: Colors.blue.shade50,
            //       border: Border.all(color: Colors.blue.shade200),
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(Icons.web, color: Colors.blue.shade600, size: 16),
            //         const SizedBox(width: 6),
            //         Text(
            //           'Web Platform',
            //           style: TextStyle(
            //             fontSize: 12,
            //             color: Colors.blue.shade600,
            //             fontWeight: FontWeight.w500,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}