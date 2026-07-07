import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/data/repository/booking_api_repository.dart';
import 'package:highfly/data/models/booking_list_model.dart';
import 'package:highfly/utils/network_connectivity_helper.dart';

// Bookings State
class BookingsState {
  final bool isLoading;
  final List<BookingListModel> bookings;
  final String? error;

  BookingsState({
    this.isLoading = false,
    this.bookings = const [],
    this.error,
  });

  BookingsState copyWith({
    bool? isLoading,
    List<BookingListModel>? bookings,
    String? error,
  }) {
    return BookingsState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      error: error,
    );
  }
}

// Bookings Controller
class BookingsController extends Notifier<BookingsState> {
  late BookingApiRepository _bookingApiRepository;
  bool _isDisposed = false;

  static const String _noInternetMessage =
      'No internet connection. Please try again later.';

  @override
  BookingsState build() {
    _bookingApiRepository = BookingApiRepository();
    // Load bookings when the provider is initialized
    loadBookings();
    return BookingsState();
  }

  // Load all bookings from API
  Future<void> loadBookings() async {
    if (_isDisposed) return;

    final hasConnection = await NetworkConnectivityHelper.hasInternetConnection();
    if (!hasConnection) {
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        error: _noInternetMessage,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final bookings = await _bookingApiRepository.getBookingsList();
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        bookings: bookings,
        error: null,
      );
    } catch (e) {
      if (_isDisposed) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('Network error: No internet connection')
            ? _noInternetMessage
            : 'Error loading bookings: ${e.toString()}',
      );
    }
  }

  void dispose() {
    _isDisposed = true;
  }
}

// Bookings Controller Provider
final bookingsControllerProvider = NotifierProvider<BookingsController, BookingsState>(() {
  return BookingsController();
});

