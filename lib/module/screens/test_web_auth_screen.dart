import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constant/app_colors.dart';
import '../widgets/web_phone_auth_widget.dart';

class TestWebAuthScreen extends ConsumerWidget {
  const TestWebAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Phone Auth Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Platform indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kIsWeb ? Colors.green.shade50 :  AppColors.primaryColor.withAlpha(5),
                  border: Border.all(
                    color: kIsWeb ? Colors.green :  AppColors.primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      kIsWeb ? Icons.web : Icons.phone_android,
                      color: kIsWeb ? Colors.green :  AppColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      kIsWeb ? 'Running on Web Platform' : 'Running on Mobile Platform',
                      style: TextStyle(
                        color: kIsWeb ? Colors.green.shade700 :  AppColors.primaryColor.withAlpha(7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Web auth widget or mobile message
              if (kIsWeb) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: const WebPhoneAuthWidget(),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.blue,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Mobile Platform Detected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This test screen is designed for web platform. '
                          'Phone authentication on mobile uses the standard sign-in screen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
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
}