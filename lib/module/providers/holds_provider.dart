import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/data/repository/booking_api_repository.dart';
import 'package:highfly/data/models/hold_list_model.dart';

// Holds State
class HoldsState {
  final bool isLoading;
  final List<HoldListModel> holds;
  final String? error;

  HoldsState({
    this.isLoading = false,
    this.holds = const [],
    this.error,
  });

  HoldsState copyWith({
    bool? isLoading,
    List<HoldListModel>? holds,
    String? error,
  }) {
    return HoldsState(
      isLoading: isLoading ?? this.isLoading,
      holds: holds ?? this.holds,
      error: error,
    );
  }
}

// Holds Controller
class HoldsController extends Notifier<HoldsState> {
  late BookingApiRepository _bookingApiRepository;
  bool _isDisposed = false;

  @override
  HoldsState build() {
    _bookingApiRepository = BookingApiRepository();
    // Load holds when the provider is initialized
    loadHolds();
    return HoldsState();
  }

  // Load all holds from API
  Future<void> loadHolds() async {
    if (_isDisposed) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final holds = await _bookingApiRepository.getHoldsList();
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        holds: holds,
        error: null,
      );
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading holds: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _isDisposed = true;
  }
}

// Holds Controller Provider
final holdsControllerProvider = NotifierProvider<HoldsController, HoldsState>(() {
  return HoldsController();
});

