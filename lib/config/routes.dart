import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data' show Uint8List;

import '../data/models/response_model/project_response_model.dart';
import '../data/models/response_model/visit_response_model.dart';
import '../module/screens/authentication/signIn_screen.dart';
import '../module/screens/authentication/signUp_screen.dart';
import '../module/screens/authentication/otp_verification_screen.dart';
import '../module/screens/dashboard/dashboard_screen.dart';
import '../module/screens/onboarding/splash_screen.dart';
import '../module/screens/visitors/visit_detail_screen.dart';
import '../module/screens/profile/profile_screen.dart';
import '../module/widgets/add_visit_dialog.dart';
import '../module/screens/projects/project_detail_screen.dart';

class Routes {
  static String splash = '/';
  static String bottomBar = '/bottomBar';
  static String signIn = '/signIn';
  static String signUp = '/signUp';
  static String otp = '/otp';
  static String dashboardScreen = '/dashboardScreen';
  static String addVisitScreen = '/addVisitScreen';
  static String visitDetailScreen = '/visitDetailScreen';
  static String profileScreen = '/profileScreen';
  static String projectDetailScreen = '/projectDetailScreen';
  static bool isPickingImage = false;
}

final _auth = FirebaseAuth.instance;


final GoRouter router = GoRouter(
  redirect: (context, state) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final location = state.uri.toString();
    debugPrint('Redirect check called for path: $location');
    debugPrint('isPickingImage flag: ${Routes.isPickingImage}');

    if (Routes.isPickingImage) {
      debugPrint('Preventing redirect during image picking');
      return null;
    }

    if (location == Routes.addVisitScreen) {
      debugPrint('Already on add visit screen, no redirect needed');
      return null;
    }

    if (location == Routes.visitDetailScreen) {
      debugPrint('Already on visit detail screen, no redirect needed');
      return null;
    }

    if (location == Routes.projectDetailScreen) {
      debugPrint('Already on project detail screen, no redirect needed');
      return null;
    }

    final isLoggedIn = _auth.currentUser != null;
    debugPrint('isLoggedIn: $isLoggedIn');

    final isSplash = location == Routes.splash;
    final isSigningIn = location == Routes.signIn;
    final isSignUp = location == Routes.signUp;

    debugPrint('isSplash: $isSplash');
    debugPrint('isSigningIn: $isSigningIn');
    debugPrint('isSignUp: $isSignUp');

    if (isLoggedIn && isSigningIn) {
      debugPrint('User is logged in, redirecting to dashboard');
      return Routes.dashboardScreen;
    }
    if (isLoggedIn && isSplash) {
      debugPrint('User is logged in but allowing splash to run for boot tasks');
      return null;
    }

    if (!isLoggedIn && location == Routes.dashboardScreen) {
      debugPrint('User is not logged in, redirecting to sign in');
      return Routes.signIn;
    }

    return null;
  },
  errorBuilder: (context, state) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Page not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('The requested page could not be found'),
          SizedBox(height: 16),
          Text('Redirecting to sign in...'),
        ],
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: Routes.signUp,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: Routes.otp,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          // Fallback to sign in if no data provided
          return const SignInScreen();
        }
        
        return OtpVerificationScreen(
          phoneNumber: extra['phoneNumber'] as String,
          verificationId: extra['verificationId'] as String,
          type: extra['type'] as OtpScreenType,
          fullName: extra['fullName'] as String?,
          reraNumber: extra['reraNumber'] as String?,
          teamLeaderName: extra['teamLeaderName'] as String?,
          idNumber: extra['idNumber'] as String?,
          profilePhoto: extra['profilePhoto'] as XFile?,
          profilePhotoBytes: extra['profilePhotoBytes'] as Uint8List?,
        );
      },
    ),
    GoRoute(
      path: Routes.dashboardScreen,
      builder: (context, state) => const DashboardScreen(),
    ),

    GoRoute(
      path: Routes.addVisitScreen,
      builder: (context, state) {
        final project = state.extra as Project?; // Cast to your Project type, make it nullable if it can be null
        debugPrint('Building AddVisitDialog with project: ${project?.name}');
        return AddVisitDialog(project: project!); // Pass the retrieved project
      },
    ),
    
    GoRoute(
      path: Routes.visitDetailScreen,
      builder: (context, state) {
        final visit = state.extra as Visit; // Cast to your Visit type
        debugPrint('Building VisitDetailScreen with visit: ${visit.visitorName}');
        return VisitDetailScreen(visit: visit); // Pass the retrieved visit
      },
    ),
    
    GoRoute(
      path: Routes.profileScreen,
      builder: (context, state) => const ProfileScreen(),
    ),
    
    GoRoute(
      path: Routes.projectDetailScreen,
      builder: (context, state) {
        final project = state.extra as Project;
        debugPrint('Building ProjectDetailScreen with project: ${project.name}');
        return ProjectDetailScreen(project: project);
      },
    ),
  ],
);