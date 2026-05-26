import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/config/constant/app_strings.dart';
import 'package:highfly/data/models/app_config_model.dart';
import 'package:highfly/data/repository/app_config_repository.dart';
import 'package:highfly/module/providers/secure_storage_provider.dart';

final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository();
});

class AppConfigState {
  final bool isLoading;
  final AppConfigResponse? config;
  final String? error;

  const AppConfigState({
    this.isLoading = false,
    this.config,
    this.error,
  });

  AppConfigState copyWith({
    bool? isLoading,
    AppConfigResponse? config,
    String? error,
  }) {
    return AppConfigState(
      isLoading: isLoading ?? this.isLoading,
      config: config ?? this.config,
      error: error,
    );
  }
}

class AppConfigController extends Notifier<AppConfigState> {
  late AppConfigRepository _repository;

  @override
  AppConfigState build() {
    _repository = ref.read(appConfigRepositoryProvider);
    _loadCachedConfig();
    return const AppConfigState();
  }

  Future<void> _loadCachedConfig() async {
    try {
      final storage = ref.read(secureStorageRepositoryProvider);
      final cached = await storage.read(key: SharedPreferenceStrings.appConfig);
      if (cached == null || cached.isEmpty) return;

      final json = jsonDecode(cached) as Map<String, dynamic>;
      final config = AppConfigResponse.fromJson(json);
      state = state.copyWith(config: config);
    } catch (e) {
      debugPrint('AppConfigController: Failed to load cached config: $e');
    }
  }

  Future<void> loadAppConfig() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.fetchAppConfig();
      state = state.copyWith(isLoading: false, config: response);

      try {
        final storage = ref.read(secureStorageRepositoryProvider);
        await storage.write(
          key: SharedPreferenceStrings.appConfig,
          value: jsonEncode(response.toJson()),
        );
      } catch (e) {
        debugPrint('AppConfigController: Failed to save config: $e');
      }
    } catch (e) {
      debugPrint('AppConfigController: Error loading app config: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final appConfigControllerProvider =
    NotifierProvider<AppConfigController, AppConfigState>(() {
  return AppConfigController();
});
