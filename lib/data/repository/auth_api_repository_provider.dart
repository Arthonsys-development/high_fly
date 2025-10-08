import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/data/repository/auth_api_repository.dart';

final authApiRepositoryProvider = Provider<AuthApiRepository>((ref) {
  return AuthApiRepository();
});