import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_strings.dart';
import 'package:highfly/module/providers/secure_storage_provider.dart';

import '../../data/repository/secure_storage_repository.dart';

// User state class
class UserState {
  final bool isLoading;
  final String? error;
  final UserData? user;

  UserState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  UserState copyWith({
    bool? isLoading,
    String? error,
    UserData? user,
  }) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

// User data class to match the secure storage structure
class UserData {
  final String id;
  final String firstName;
  final String phoneNumber;
  final String profilePhoto;

  UserData({
    required this.id,
    required this.firstName,
    required this.phoneNumber,
    required this.profilePhoto,
  });

  String get initials {
    if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }
    return 'U';
  }
}

// User controller
class UserController extends Notifier<UserState> {
  late SecureStorageRepository _secureStorage;

  @override
  UserState build() {
    _secureStorage = ref.watch(secureStorageRepositoryProvider);
    _loadUserData();
    return UserState(isLoading: true);
  }

  // Load user data from secure storage
  Future<void> _loadUserData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Read user data from secure storage
      final id = await _secureStorage.read(key: SharedPreferenceStrings.id) ?? '';
      final firstName = await _secureStorage.read(key: SharedPreferenceStrings.firstName) ?? '';
      final phoneNumber = await _secureStorage.read(key: SharedPreferenceStrings.phoneNumber) ?? '';
      final profilePhoto = await _secureStorage.read(key: SharedPreferenceStrings.profilePhoto) ?? '';

      if (id.isNotEmpty && firstName.isNotEmpty) {
        final userData = UserData(
          id: id,
          firstName: firstName,
          phoneNumber: phoneNumber,
          profilePhoto: profilePhoto,
        );

        state = state.copyWith(
          isLoading: false,
          user: userData,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No user data found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user data: $e',
      );
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  // Clear user data (for logout)
  Future<void> clearUserData() async {
    state = state.copyWith(
      isLoading: false,
      user: null,
      error: null,
    );
  }
}

// Provider for the user controller
final userControllerProvider = NotifierProvider<UserController, UserState>(() {
  return UserController();
});

