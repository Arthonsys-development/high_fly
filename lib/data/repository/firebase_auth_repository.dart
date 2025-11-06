import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web-specific helpers
import 'web_firebase_helper.dart' if (dart.library.io) 'web_firebase_helper_stub.dart';

class FirebaseAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? _verificationId;
  ConfirmationResult? _webConfirmationResult; // For web platform

  // Check if Firebase is initialized
  Future<bool> _ensureFirebaseInitialized() async {
    try {
      await Firebase.initializeApp();
      print('🔥 Firebase: Initialized successfully');
      return true;
    } catch (e) {
      print('🔥 Firebase: Initialization error: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Send OTP to phone number
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerificationCompleted,
  }) async {
    try {
      // Ensure Firebase is initialized
      final isInitialized = await _ensureFirebaseInitialized();
      if (!isInitialized) {
        onError('Firebase initialization failed. Please check your configuration.');
        return;
      }
      
      print('🔥 Firebase Auth: Starting phone verification for $phoneNumber');
      print('🔥 Firebase Auth: Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('🔥 Firebase Auth: Current user: ${_firebaseAuth.currentUser}');
      
      if (kIsWeb) {
        // Web platform - use signInWithPhoneNumber with reCAPTCHA
        await _sendOTPWeb(
          phoneNumber: phoneNumber,
          onCodeSent: onCodeSent,
          onError: onError,
          onAutoVerificationCompleted: onAutoVerificationCompleted,
        );
      } else {
        // Mobile platform - use verifyPhoneNumber
        await _sendOTPMobile(
          phoneNumber: phoneNumber,
          onCodeSent: onCodeSent,
          onError: onError,
          onAutoVerificationCompleted: onAutoVerificationCompleted,
        );
      }
    } catch (e) {
      print('🔥 Firebase Auth: Exception during sendOTP: $e');
      onError('Failed to send OTP: ${e.toString()}');
    }
  }
  
  // Web-specific OTP sending
  Future<void> _sendOTPWeb({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerificationCompleted,
  }) async {
    try {
      print('🔥 Firebase Auth Web: Starting phone sign-in for web platform');
      print('🔥 Firebase Auth Web: Phone number: $phoneNumber');
      
      // Initialize web Firebase helper
      await WebFirebaseAuth.initializeRecaptcha();
      
      // Show reCAPTCHA container
      WebFirebaseAuth.showRecaptcha();
      
      try {
        // For web, we'll use the ConfirmationResult approach
        print('🔥 Firebase Auth Web: Creating reCAPTCHA verifier');
        
        // Show loading state
        print('🔥 Firebase Auth Web: Preparing reCAPTCHA...');
        
        // Use Firebase Auth's signInWithPhoneNumber for web
        // This method automatically handles reCAPTCHA on web
        final confirmationResult = await _firebaseAuth.signInWithPhoneNumber(phoneNumber);
        
        print('🔥 Firebase Auth Web: SMS sent successfully');
        _webConfirmationResult = confirmationResult;
        _verificationId = 'web_verification_${DateTime.now().millisecondsSinceEpoch}';
        
        // Hide reCAPTCHA after successful verification
        WebFirebaseAuth.hideRecaptcha();
        
        onCodeSent(_verificationId!);
              
      } catch (e) {
        WebFirebaseAuth.hideRecaptcha();
        print('🔥 Firebase Auth Web: Phone verification error: $e');
        
        // Handle specific web authentication errors
        if (e.toString().contains('auth/invalid-phone-number')) {
          onError('Invalid phone number. Please enter a valid international phone number (+country code).');
        } else if (e.toString().contains('too-many-requests')) {
          onError('Too many requests. Please wait a few minutes before trying again.');
        } else if (e.toString().contains('auth/operation-not-allowed')) {
          onError('Phone authentication is not enabled in Firebase Console.\n\nTo fix this:\n1. Go to Firebase Console → Authentication → Sign-in method\n2. Enable Phone provider\n3. Add localhost to authorized domains');
        } else if (e.toString().contains('auth/missing-app-credential') || e.toString().contains('auth/app-not-authorized')) {
          onError('App not authorized for phone authentication.\n\nPlease:\n1. Enable Phone Auth in Firebase Console\n2. Add localhost to authorized domains\n3. Ensure reCAPTCHA is properly configured');
        } else if (e.toString().contains('captcha') || e.toString().contains('recaptcha')) {
          onError('reCAPTCHA verification failed. Please try again.\n\nNote: Please allow pop-ups and ensure JavaScript is enabled.');
        } else if (e.toString().contains('auth/network-request-failed')) {
          onError('Network error. Please check your internet connection and try again.');
        } else {
          onError('Phone verification failed: ${e.toString()}\n\nPlease ensure:\n• Phone number includes country code\n• Pop-ups are allowed\n• Phone Auth is enabled in Firebase Console');
        }
      }
      
    } catch (e) {
      WebFirebaseAuth.hideRecaptcha();
      print('🔥 Firebase Auth Web: Setup error: $e');
      onError('Web phone authentication setup error: ${e.toString()}');
    }
  }
  
  // Mobile-specific OTP sending with enhanced error handling
  Future<void> _sendOTPMobile({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function() onAutoVerificationCompleted,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('🔥 Firebase Auth: Auto-verification completed');
          // Auto-verification completed
          try {
            await _firebaseAuth.signInWithCredential(credential);
            onAutoVerificationCompleted();
          } catch (e) {
            print('🔥 Firebase Auth: Auto verification failed: $e');
            onError('Auto verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('🔥 Firebase Auth: Verification failed with code: ${e.code}');
          print('🔥 Firebase Auth: Error message: ${e.message}');
          print('🔥 Firebase Auth: Error details: ${e.toString()}');
          _handleMobileAuthError(e, onError);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('🔥 Firebase Auth: Code sent successfully');
          print('🔥 Firebase Auth: Verification ID: $verificationId');
          print('🔥 Firebase Auth: Resend token: $resendToken');
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('🔥 Firebase Auth: Code auto-retrieval timeout');
          print('🔥 Firebase Auth: Verification ID: $verificationId');
          // Even though auto-retrieval timed out, the OTP was still sent
          // So we should call onCodeSent to notify that the code was sent
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e, stackTrace) {
      print('🔥 Firebase Auth: Unexpected error in verifyPhoneNumber: $e');
      print('🔥 Firebase Auth: Stack trace: $stackTrace');
      
      // Handle the specific iOS crash scenario
      if (e.toString().contains('nil') && e.toString().contains('implicitly unwrapping')) {
        onError('Firebase configuration error on iOS. Please check:\n1. GoogleService-Info.plist is correct\n2. AppDelegate initializes Firebase\n3. Run "pod install" in iOS directory');
      } else {
        onError('Failed to send OTP. Please try again: ${e.toString()}');
      }
    }
  }
  
  // Handle mobile authentication errors
  void _handleMobileAuthError(FirebaseAuthException e, Function(String) onError) {
    String errorMessage;
    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'The phone number entered is invalid.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many requests. Try again later.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Phone authentication is not enabled. Please enable it in Firebase Console.';
        break;
      case 'configuration-not-found':
        errorMessage = 'Firebase configuration error. Please:\n1. Enable Phone Authentication in Firebase Console\n2. Check GoogleService-Info.plist is properly configured\n3. Verify your bundle ID matches Firebase Console';
        break;
      case 'web-network-request-failed':
      case 'network-request-failed':
        errorMessage = 'Phone verification failed due to APNs configuration.\n\niOS Phone Auth requires either:\n1. APNs certificates configured in Firebase Console, OR\n2. reCAPTCHA verification (automatic fallback)\n\nPlease try again. If the issue persists:\n• Check your internet connection\n• Ensure you have a valid phone number\n• Contact support for APNs setup assistance';
        break;
      case 'app-not-authorized':
        errorMessage = 'App not authorized for Firebase Phone Auth.\n\nTo fix:\n1. Verify bundle ID in GoogleService-Info.plist matches your app\n2. Ensure Phone Auth is enabled in Firebase Console\n3. Check that your app is registered in Firebase';
        break;
      case 'unknown':
        if (e.message?.contains('BILLING_NOT_ENABLED') == true) {
          errorMessage = 'Firebase billing is required for phone authentication.\n\nTo fix this:\n1. Go to Firebase Console\n2. Navigate to Project Settings > Usage and billing\n3. Upgrade to Blaze (Pay as you go) plan\n\nNote: Phone auth has generous free quotas.';
        } else if (e.message?.contains('CONFIGURATION_NOT_FOUND') == true) {
          errorMessage = 'Firebase configuration not found. Please check your Firebase setup.';
        } else if (e.message?.contains('APNs') == true || e.message?.contains('push notification') == true) {
          errorMessage = 'APNs (Apple Push Notifications) is required for iOS phone authentication.\n\nTo fix:\n1. Enable APNs in Firebase Console\n2. Upload APNs certificate or key\n3. Rebuild and retry\n\nFor development, reCAPTCHA fallback is available.';
        } else {
          errorMessage = 'An unknown error occurred. Please try again or contact support.';
        }
        break;
      default:
        errorMessage = 'Verification failed: ${e.message}';
    }
    onError(errorMessage);
  }

  // Verify OTP and sign in
  Future<UserCredential?> verifyOTP({
    required String otpCode,
    String? verificationId,
  }) async {
    try {
      if (kIsWeb) {
        // Web platform - use ConfirmationResult
        return await _verifyOTPWeb(otpCode);
      } else {
        // Mobile platform - use PhoneAuthCredential
        return await _verifyOTPMobile(otpCode, verificationId);
      }
    } catch (e) {
      print('🔥 Firebase Auth: Exception during verifyOTP: $e');
      rethrow;
    }
  }
  
  // Web-specific OTP verification
  Future<UserCredential?> _verifyOTPWeb(String otpCode) async {
    try {
      if (_webConfirmationResult == null) {
        throw 'Verification session not found. Please request OTP again.';
      }
      
      final UserCredential result = await _webConfirmationResult!.confirm(otpCode);
      print('🔥 Firebase Auth Web: OTP verification successful');
      return result;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The verification code entered is invalid.';
          break;
        case 'session-expired':
          errorMessage = 'The verification session has expired. Please request a new OTP.';
          break;
        default:
          errorMessage = 'Web verification failed: ${e.message}';
      }
      throw errorMessage;
    } catch (e) {
      throw 'Failed to verify OTP: ${e.toString()}';
    }
  }
  
  // Mobile-specific OTP verification
  Future<UserCredential?> _verifyOTPMobile(String otpCode, String? verificationId) async {
    try {
      final String verId = verificationId ?? _verificationId ?? '';
      if (verId.isEmpty) {
        throw 'Verification ID not found. Please request OTP again.';
      }

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verId,
        smsCode: otpCode,
      );

      final UserCredential result = await _firebaseAuth.signInWithCredential(credential);
      print('🔥 Firebase Auth Mobile: OTP verification successful');
      return result;
    } on FirebaseAuthException catch (e) {
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
      throw errorMessage;
    } catch (e) {
      throw 'Failed to verify OTP: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw 'Failed to sign out: ${e.toString()}';
    }
  }

  // Resend OTP
  Future<void> resendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerificationCompleted: () {},
    );
  }

  // Get verification ID
  String? get verificationId => _verificationId;

  // Check if user is signed in
  bool get isSignedIn => _firebaseAuth.currentUser != null;

  // Get current user's ID token
  Future<String?> getIdToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      print('🔥 Firebase Auth: Failed to get ID token: $e');
      return null;
    }
  }

  // Get current user's ID token with forced refresh
  Future<String?> getIdTokenWithRefresh() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken(true);
    } catch (e) {
      print('🔥 Firebase Auth: Failed to get ID token with refresh: $e');
      return null;
    }
  }
}