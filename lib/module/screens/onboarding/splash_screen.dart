import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_strings.dart';
import 'package:highfly/module/providers/organization_provider.dart';
import 'package:highfly/module/widgets/organization_logo.dart';

import '../../../config/routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrganizationAndNavigate();
  }

  Future<void> _loadOrganizationAndNavigate() async {
    try {
      final organization = await ref
          .read(organizationProvider.notifier)
          .loadOrganization(forceRefresh: true);

      if (organization != null &&
          (organization.isActive == false ||
              organization.isSubscriptionActive == false)) {
        await _forceLogoutDueToOrganizationStatus();
        return;
      }
    } catch (error) {
      debugPrint('SplashScreen: Failed to load organization: $error');
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      context.go(Routes.signIn);
    }
  }

  Future<void> _forceLogoutDueToOrganizationStatus() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('SplashScreen: Error signing out user - $e');
    }

    try {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
    } catch (e) {
      debugPrint('SplashScreen: Error clearing secure storage - $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your organization access is inactive. You have been signed out.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
    context.go(Routes.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final organizationState = ref.watch(organizationProvider);
    final organizationName = organizationState.asData?.value?.name ?? GlobalStrings.appName;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const OrganizationLogo(
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 24),
              Text(
                organizationName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Preparing your workspace...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
