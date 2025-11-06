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
import '../module/screens/visitors/visit_detail_screen.dart';
import '../module/screens/profile/profile_screen.dart';
import '../module/widgets/add_visit_dialog.dart';

class Routes {
  static String bottomBar = '/bottomBar';
  static String signIn = '/signIn';
  static String signUp = '/signUp';
  static String otp = '/otp';
  static String dashboardScreen = '/dashboardScreen';
  static String addVisitScreen = '/addVisitScreen';
  static String visitDetailScreen = '/visitDetailScreen';
  static String profileScreen = '/profileScreen';
  static bool isPickingImage = false;
}

final _auth = FirebaseAuth.instance;


final GoRouter router = GoRouter(
  redirect: (context, state) async {
    // Add a small delay to allow flags to be set
    await Future.delayed(const Duration(milliseconds: 100));
    
    debugPrint('Redirect check called for path: ${state.uri.toString()}');
    debugPrint('isPickingImage flag: ${Routes.isPickingImage}');
    
    // Don't redirect if we're in the middle of picking an image
    if (Routes.isPickingImage) {
      debugPrint('Preventing redirect during image picking');
      return null;
    }
    
    // Don't redirect if we're already on the add visit screen
    if (state.uri.toString() == Routes.addVisitScreen) {
      debugPrint('Already on add visit screen, no redirect needed');
      return null;
    }
    
    // Don't redirect if we're already on the visit detail screen
    if (state.uri.toString() == Routes.visitDetailScreen) {
      debugPrint('Already on visit detail screen, no redirect needed');
      return null;
    }
    
    final isLoggedIn = _auth.currentUser != null;
    debugPrint('isLoggedIn: $isLoggedIn');
    
    final isSigningIn = state.uri.toString() == Routes.signIn || state.uri.toString() == '/';
    debugPrint('isSigningIn: $isSigningIn');
    
    final isSignUp = state.uri.toString() == Routes.signUp;
    debugPrint('isSignUp: $isSignUp');
    
    // If user is logged in and trying to access sign in or root, redirect to dashboard
    // But only if we're not currently on a screen that should stay active
    if (isLoggedIn && (isSigningIn || state.uri.toString() == '/')) {
      debugPrint('User is logged in, redirecting to dashboard');
      return Routes.dashboardScreen;
    }
    
    // If user is not logged in and trying to access protected routes, redirect to sign in
    if (!isLoggedIn && state.uri.toString() == Routes.dashboardScreen) {
      debugPrint('User is not logged in, redirecting to sign in');
      return Routes.signIn;
    }
    
    debugPrint('No redirect needed for path: ${state.uri.toString()}');
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
      path: '/',
      builder: (context, state) => const SignInScreen(),
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
  ],
);