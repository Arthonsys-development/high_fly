import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:highfly/data/models/response_model/organization_response_model.dart';
import 'package:highfly/data/repository/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository();
});

final organizationProvider =
    StateNotifierProvider<OrganizationNotifier, AsyncValue<Organization?>>(
  (ref) => OrganizationNotifier(ref.read(organizationRepositoryProvider)),
);

class OrganizationNotifier extends StateNotifier<AsyncValue<Organization?>> {
  OrganizationNotifier(this._repository)
      : super(const AsyncValue.loading());

  final OrganizationRepository _repository;
  bool _hasLoadedOnce = false;

  Future<Organization?> loadOrganization({bool forceRefresh = false}) async {
    if (_hasLoadedOnce && !forceRefresh && state.hasValue) {
      return state.value;
    }

    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => _repository.fetchOrganization());
    state = result;

    if (result.hasValue) {
      _hasLoadedOnce = true;
    }

    return result.value;
  }
}

