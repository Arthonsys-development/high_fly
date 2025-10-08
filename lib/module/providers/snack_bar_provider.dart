
import 'package:flutter_riverpod/legacy.dart';

class SnackBarNotifier extends StateNotifier<String?> {
  SnackBarNotifier() : super(null);

  void showSnackBar(String message) {
    state = message;  // Update the state with the snackBar message
  }

  void clearSnackBar() {
    state = null;  // Clear the snackBar message
  }
}

final snackBarProvider = StateNotifierProvider<SnackBarNotifier, String?>(
      (ref) => SnackBarNotifier(),
);
