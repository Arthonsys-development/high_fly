import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highfly/data/models/notification_model.dart';
import 'package:highfly/data/repository/notification_api_repository.dart';

class NotificationState {
  final bool isLoading;
  final NotificationsModel? notifications;
  final String? error;

  NotificationState({
    this.isLoading = false,
    this.notifications,
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    NotificationsModel? notifications,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error,
    );
  }

  int get unreadCount => notifications?.unreadCount ?? 0;
}

class NotificationController extends Notifier<NotificationState> {
  late NotificationApiRepository _repository;

  @override
  NotificationState build() {
    _repository = NotificationApiRepository();
    Future.microtask(loadNotifications);
    return NotificationState(isLoading: true);
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.fetchNotifications();
      state = NotificationState(isLoading: false, notifications: result);
    } catch (e) {
      debugPrint('NotificationController: Error loading notifications: $e');
      state = NotificationState(
        isLoading: false,
        error: 'Failed to load notifications',
      );
    }
  }
}

final notificationControllerProvider =
    NotifierProvider<NotificationController, NotificationState>(
  NotificationController.new,
);
