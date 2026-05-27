class AppConfigData {
  final bool isHoldAvailable;
  final bool holdEnabled;
  final String holdStartDate;
  final String holdOffDate;
  final int maxPlotSelect;
  final int holdDurationHours;
  final int currentHoldBookings;
  final int maxHoldsPerAgent;
  final String systemName;

  AppConfigData({
    required this.isHoldAvailable,
    required this.holdEnabled,
    required this.holdStartDate,
    required this.holdOffDate,
    required this.maxPlotSelect,
    required this.holdDurationHours,
    required this.currentHoldBookings,
    required this.maxHoldsPerAgent,
    required this.systemName,
  });

  /// Hold bookings the agent can still create (not plot count).
  int get remainingHoldBookings {
    final remaining = maxHoldsPerAgent - currentHoldBookings;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether the agent can start another hold booking.
  bool get canCreateNewHold => currentHoldBookings < maxHoldsPerAgent;

  /// Max plots selectable in a single hold booking.
  int get maxPlotsPerHold {
    final limit = maxPlotSelect;
    return limit < 1 ? 1 : limit;
  }

  factory AppConfigData.fromJson(Map<String, dynamic> json) {
    return AppConfigData(
      isHoldAvailable: json['is_hold_available'] as bool? ?? false,
      holdEnabled: json['hold_enabled'] as bool? ?? false,
      holdStartDate: json['hold_start_date'] as String? ?? '',
      holdOffDate: json['hold_off_date'] as String? ?? '',
      maxPlotSelect: json['max_plot_select'] as int? ?? 1,
      holdDurationHours: json['hold_duration_hours'] as int? ?? 24,
      currentHoldBookings: json['current_hold_bookings'] as int? ?? 0,
      maxHoldsPerAgent: json['max_holds_per_agent'] as int? ?? 1,
      systemName: json['system_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_hold_available': isHoldAvailable,
      'hold_enabled': holdEnabled,
      'hold_start_date': holdStartDate,
      'hold_off_date': holdOffDate,
      'max_plot_select': maxPlotSelect,
      'hold_duration_hours': holdDurationHours,
      'current_hold_bookings': currentHoldBookings,
      'max_holds_per_agent': maxHoldsPerAgent,
      'system_name': systemName,
    };
  }
}

class AppConfigResponse {
  final bool success;
  final AppConfigData? config;

  AppConfigResponse({
    required this.success,
    this.config,
  });

  factory AppConfigResponse.fromJson(Map<String, dynamic> json) {
    final configJson = json['config'];
    return AppConfigResponse(
      success: json['success'] as bool? ?? false,
      config: configJson is Map<String, dynamic>
          ? AppConfigData.fromJson(configJson)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (config != null) 'config': config!.toJson(),
    };
  }
}
