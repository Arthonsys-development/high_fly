import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:highfly/config/constant/app_strings.dart';
import '../../data/repository/firebase_auth_repository.dart';
import '../../data/repository/auth_api_repository_provider.dart';
import '../../data/models/request_models/auth_request_model.dart';
import '../../data/repository/auth_api_repository.dart';
import '../../config/network/base_url_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Add FCM provider import
import '../providers/fcm_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/analytics_provider.dart';

// Firebase Auth Repository Provider
final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(firebaseAuthRepositoryProvider);
  return authRepository.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authRepository = ref.watch(firebaseAuthRepositoryProvider);
  return authRepository.currentUser;
});

// Auth State for Sign In Screen
class AuthState {
  final bool isLoading;
  final bool isOtpSent;
  final String? error;
  final String? phoneNumber;
  final String? verificationId;

  AuthState({
    this.isLoading = false,
    this.isOtpSent = false,
    this.error,
    this.phoneNumber,
    this.verificationId,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isOtpSent,
    String? error,
    String? phoneNumber,
    String? verificationId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      error: error,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

// Auth Controller
class AuthController extends Notifier<AuthState> {
  late FirebaseAuthRepository _authRepository;
  late AuthApiRepository _authApiRepository;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static final List<String> _secureStorageKeys = [
    SharedPreferenceStrings.accessToken,
    SharedPreferenceStrings.id,
    SharedPreferenceStrings.firstName,
    SharedPreferenceStrings.fullName,
    SharedPreferenceStrings.phoneNumber,
    SharedPreferenceStrings.profilePhoto,
    'access_token',
    'user_data',
  ];

  @override
  AuthState build() {
    _authRepository = ref.read(firebaseAuthRepositoryProvider);
    _authApiRepository = ref.read(authApiRepositoryProvider);
    return AuthState();
  }

  Future<void> _cleanupFailedLogin() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      debugPrint('AuthController: Failed to sign out after login failure - $e');
    }

    for (final key in _secureStorageKeys) {
      try {
        await _secureStorage.delete(key: key);
      } catch (e) {
        debugPrint('AuthController: Failed to clear $key after login failure - $e');
      }
    }
  }

  // Register device for notifications
  Future<void> registerDeviceForNotifications() async {
    try {
      final fcmService = ref.read(fcmProvider);
      // Request notification permissions
      final permissionGranted = await fcmService.requestNotificationPermission();
      
      if (permissionGranted) {
        // Get FCM token
        final token = await fcmService.getFcmToken();
        if (token != null) {
          // Register token with backend
          await fcmService.registerToken(token);
        }
      } else {
        // Permission not granted - just log it, don't interrupt user flow
        // User can enable notifications later from app settings if they want
        debugPrint('Notification permission not granted - user can enable later from settings');
      }
    } catch (e) {
      // Don't fail if notification registration fails
      debugPrint('Failed to register for notifications: $e');
    }
  }

  // Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    await _authRepository.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        state = state.copyWith(
          isLoading: false,
          isOtpSent: true,
          phoneNumber: phoneNumber,
          verificationId: verificationId,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
      },
      onAutoVerificationCompleted: () {
        state = state.copyWith(
          isLoading: false,
          isOtpSent: false,
        );
      },
    );
  }

  // Verify OTP
  Future<bool> verifyOTP(String otpCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userCredential = await _authRepository.verifyOTP(
        otpCode: otpCode,
        verificationId: state.verificationId,
      );
      
      if (userCredential != null) {
        // Get Firebase ID token
        final String? idToken = await _authRepository.getIdToken();
        
        if (idToken == null) {
          throw 'Failed to get Firebase ID token';
        }
        
        // Verify login token with backend API
        final loginTokenRequest = LoginTokenRequest(
          idToken: idToken,
          phoneNumber: state.phoneNumber,
        );
        final result = await _authApiRepository.verifyToken(loginTokenRequest);
        
        final tokenVerificationSucceeded = result['success'] == true;
        if (!tokenVerificationSucceeded) {
          final message = result['message']?.toString() ?? 'Login token verification failed';
          await _cleanupFailedLogin();
          throw message;
        }
        
        final data = result['data'];
        if (data is! Map) {
          await _cleanupFailedLogin();
          throw 'Invalid response received from login API';
        }

        // Save access token to secure storage
        final accessToken = data['access_token']?.toString() ?? '';
        final agent = data['agent'];
        if (agent is! Map) {
          await _cleanupFailedLogin();
          throw 'Invalid agent information received from login API';
        }

        final id = agent['id']?.toString() ?? '';
        final fName = agent['full_name']?.toString() ?? '';
        final fullName = agent['full_name']?.toString() ?? '';
        final user = agent['user'];
        final phoneNumber = (user is Map ? user['phone_number'] : null)?.toString() ?? '';
        final profileImage = (user is Map ? user['profile_image'] : null)?.toString() ?? '';

        if (accessToken.isEmpty || id.isEmpty) {
          await _cleanupFailedLogin();
          throw 'Missing authentication data from server response';
        }
        await _secureStorage.write(key: SharedPreferenceStrings.accessToken, value: accessToken);
        await _secureStorage.write(key: SharedPreferenceStrings.id, value: id.toString());
        await _secureStorage.write(key: SharedPreferenceStrings.firstName, value: fName);
        await _secureStorage.write(key: SharedPreferenceStrings.fullName, value: fullName);
        await _secureStorage.write(key: SharedPreferenceStrings.phoneNumber, value: phoneNumber);
        await _secureStorage.write(key: SharedPreferenceStrings.profilePhoto, value: BaseUrlConfig.buildImageUrl(profileImage));

        // Register device for notifications after successful sign-in
        await registerDeviceForNotifications();

        // Log analytics event for successful login
        try {
          final analyticsService = ref.read(analyticsProvider);
          await analyticsService.logLogin(method: 'phone_otp');
          // Set user ID for analytics
          await analyticsService.setUserId(id);
        } catch (e) {
          debugPrint('Error logging login analytics: $e');
        }

        // Load user profile after successful login
        try {
          debugPrint('🔄 AuthProvider: Loading user profile after login...');
          final profileNotifier = ref.read(profileProvider.notifier);
          await profileNotifier.loadProfile();
          debugPrint('✅ AuthProvider: Profile loaded successfully');
        } catch (e) {
          debugPrint('⚠️ AuthProvider: Failed to load profile after login - $e');
          // Don't fail the login if profile loading fails
        }

        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Verification failed',
        );
        return false;
      }
    } catch (e) {
      await _cleanupFailedLogin();
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Resend OTP
  Future<void> resendOTP() async {
    if (state.phoneNumber != null) {
      await sendOTP(state.phoneNumber!);
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset state
  void reset() {
    state = AuthState();
  }
}

// Auth Controller Provider
final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});