import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/response_model/project_response_model.dart';

/// State class to hold booking navigation data
class BookingNavigationState {
  final Project? selectedProject;
  final int? tabIndex; // 0 for Book Now, 1 for Hold
  final bool shouldNavigate;

  const BookingNavigationState({
    this.selectedProject,
    this.tabIndex,
    this.shouldNavigate = false,
  });

  BookingNavigationState copyWith({
    Project? selectedProject,
    int? tabIndex,
    bool? shouldNavigate,
  }) {
    return BookingNavigationState(
      selectedProject: selectedProject ?? this.selectedProject,
      tabIndex: tabIndex ?? this.tabIndex,
      shouldNavigate: shouldNavigate ?? this.shouldNavigate,
    );
  }
}

/// Notifier for managing booking navigation state
class BookingNavigationNotifier extends Notifier<BookingNavigationState> {
  @override
  BookingNavigationState build() {
    return const BookingNavigationState();
  }

  /// Navigate to booking screen with a project and tab selection
  void navigateToBooking(Project project, int tabIndex) {
    state = BookingNavigationState(
      selectedProject: project,
      tabIndex: tabIndex,
      shouldNavigate: true,
    );
  }

  /// Clear navigation state after handling
  void clearNavigation() {
    state = const BookingNavigationState(
      selectedProject: null,
      tabIndex: null,
      shouldNavigate: false,
    );
  }

  /// Reset all state
  void reset() {
    state = const BookingNavigationState();
  }
}

/// Provider instance
final bookingNavigationProvider = NotifierProvider<BookingNavigationNotifier, BookingNavigationState>(() {
  return BookingNavigationNotifier();
});

