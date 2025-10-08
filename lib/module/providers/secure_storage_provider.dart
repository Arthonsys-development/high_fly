import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/repository/secure_storage_repository.dart';

/// Provides the [FlutterSecureStorage] instance
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

/// Provides the [SecureStorageRepository] abstraction
final secureStorageRepositoryProvider = Provider<SecureStorageRepository>((
  ref,
) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorageRepositoryImpl(storage);
});
