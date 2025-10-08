import 'package:flutter_secure_storage/flutter_secure_storage.dart';


abstract class SecureStorageRepository {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> clear();
}

class SecureStorageRepositoryImpl implements SecureStorageRepository {
  final FlutterSecureStorage _storage;

  SecureStorageRepositoryImpl(this._storage);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}