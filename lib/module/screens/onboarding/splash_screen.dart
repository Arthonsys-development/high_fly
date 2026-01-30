import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:highfly/config/constant/app_strings.dart';
import 'package:highfly/module/providers/organization_provider.dart';
import 'package:highfly/module/widgets/organization_logo.dart';
import 'package:highfly/utils/app_update_service.dart';

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

      // Check for app updates
      if (organization != null && mounted) {
        await _checkForAppUpdate(organization);
      }
    } catch (error) {
      debugPrint('SplashScreen: Failed to load organization: $error');
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) {
        return;
      }
      context.go(Routes.signIn);
    }
  }

  Future<void> _checkForAppUpdate(organization) async {
    try {
      final (isUpdateAvailable, isMandatory, message) =
          await AppUpdateService.checkForUpdate(organization);

      if (isUpdateAvailable && mounted) {
        final shouldUpdate = await AppUpdateService.showUpdateDialog(
          context: context,
          isMandatory: isMandatory,
          message: message,
        );

        if (shouldUpdate) {
          await AppUpdateService.openAppStore();
          // If mandatory, don't proceed with navigation
          if (isMandatory) {
            // Keep the user on this screen
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please update the app to continue'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
            // Prevent navigation by throwing an exception
            throw Exception('Mandatory update required');
          }
        } else if (isMandatory) {
          // User tried to dismiss mandatory update - keep them on splash
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Update is required to use the app'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          throw Exception('Mandatory update required');
        }
      }
    } catch (error) {
      debugPrint('SplashScreen: Error checking for updates: $error');
      // If it's a mandatory update exception, rethrow it
      if (error.toString().contains('Mandatory update required')) {
        rethrow;
      }
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
