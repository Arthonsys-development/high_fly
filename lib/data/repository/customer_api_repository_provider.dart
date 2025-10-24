import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/data/repository/customer_api_repository.dart';

final customerApiRepositoryProvider = Provider<CustomerApiRepository>((ref) {
  return CustomerApiRepository();
});
