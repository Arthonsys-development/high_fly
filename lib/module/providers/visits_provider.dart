import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/data/repository/auth_api_repository.dart';
import 'package:highfly/data/models/response_model/visit_response_model.dart';

// Visits State
class VisitsState {
  final bool isLoading;
  final List<Visit> visits;
  final String? error;

  VisitsState({
    this.isLoading = false,
    this.visits = const [],
    this.error,
  });

  VisitsState copyWith({
    bool? isLoading,
    List<Visit>? visits,
    String? error,
  }) {
    return VisitsState(
      isLoading: isLoading ?? this.isLoading,
      visits: visits ?? this.visits,
      error: error,
    );
  }
}

// Visits Controller
class VisitsController extends Notifier<VisitsState> {
  late AuthApiRepository _authApiRepository;
  bool _isDisposed = false;

  @override
  VisitsState build() {
    _authApiRepository = AuthApiRepository();
    // Load visits when the provider is initialized
    print('VisitsController: Initializing and loading visits...');
    loadVisits();
    return VisitsState();
  }

  // Load visits from API
  Future<void> loadVisits() async {
    if (_isDisposed) return;
    print('VisitsController: Loading visits...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authApiRepository.getVisits();
      if (_isDisposed) return;
      print('VisitsController: Visits API result success: ${result['success']}');
      print('VisitsController: Visits API result data length: ${result['data']?.length ?? 0}');
      
      if (result['success']) {
        final visits = result['data'] as List<Visit>;
        print('VisitsController: Successfully loaded ${visits.length} visits');
        if (!_isDisposed) {
          state = state.copyWith(
            isLoading: false,
            visits: visits,
            error: null,
          );
        }
        print('VisitsController: State updated with ${visits.length} visits');
      } else {
        if (_isDisposed) return;
        final errorMessage = result['message'] as String? ?? 'Failed to load visits';
        print('VisitsController: Failed to load visits: $errorMessage');
        if (!_isDisposed) {
          state = state.copyWith(
            isLoading: false,
            error: errorMessage,
          );
        }
      }
    } catch (e, stackTrace) {
      if (_isDisposed) return;
      print('VisitsController: Exception while loading visits: $e');
      print('VisitsController: Stack trace: $stackTrace');
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: 'Error loading visits: ${e.toString()}',
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // super.dispose();
  }
}

// Visits Controller Provider
final visitsControllerProvider = NotifierProvider<VisitsController, VisitsState>(() {
  return VisitsController();
});