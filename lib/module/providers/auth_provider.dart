import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:highfly/config/constant/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/repository/firebase_auth_repository.dart';
import '../../data/repository/auth_api_repository_provider.dart';
import '../../data/models/request_models/auth_request_model.dart';
import '../../data/repository/auth_api_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Add FCM provider import
import '../providers/fcm_provider.dart';
import '../providers/profile_provider.dart';

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

  @override
  AuthState build() {
    _authRepository = ref.read(firebaseAuthRepositoryProvider);
    _authApiRepository = ref.read(authApiRepositoryProvider);
    return AuthState();
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
      }else{
        openAppSettings();
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
        final loginTokenRequest = LoginTokenRequest(idToken: idToken);
        final result = await _authApiRepository.verifyToken(loginTokenRequest);
        
        if (!result['success']) {
          throw result['message'] ?? 'Login token verification failed';
        }
        
        // Save access token to secure storage
        final accessToken = result['data']['access_token'] ?? '';
        final id = result['data']['agent']['id'] ?? '';
        final fName = result['data']['agent']['full_name'] ?? '';
        final fullName = result['data']['agent']['full_name'] ?? '';
        final phoneNumber = result['data']['agent']['user']['phone_number'] ?? '';
        final profileImage = result['data']['agent']['user']['profile_image'] ?? '';
        if (accessToken != null) {
          await _secureStorage.write(key: SharedPreferenceStrings.accessToken, value: accessToken);
        }
        await _secureStorage.write(key: SharedPreferenceStrings.id, value: id.toString());
        await _secureStorage.write(key: SharedPreferenceStrings.firstName, value: fName);
        await _secureStorage.write(key: SharedPreferenceStrings.fullName, value: fullName);
        await _secureStorage.write(key: SharedPreferenceStrings.phoneNumber, value: phoneNumber);
        await _secureStorage.write(key: SharedPreferenceStrings.profilePhoto, value: "${dotenv.env['BASE_URL_IMAGE']}$profileImage");

        // Register device for notifications after successful sign-in
        await registerDeviceForNotifications();

        // Load user profile after successful login
        try {
          print('🔄 AuthProvider: Loading user profile after login...');
          final profileNotifier = ref.read(profileProvider.notifier);
          await profileNotifier.loadProfile();
          print('✅ AuthProvider: Profile loaded successfully');
        } catch (e) {
          print('⚠️ AuthProvider: Failed to load profile after login - $e');
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