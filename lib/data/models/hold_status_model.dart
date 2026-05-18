class HoldStatusData {
  final bool holdEnabled;
  final String holdStartDate;
  final String holdOffDate;

  HoldStatusData({
    required this.holdEnabled,
    required this.holdStartDate,
    required this.holdOffDate,
  });

  factory HoldStatusData.fromJson(Map<String, dynamic> json) {
    return HoldStatusData(
      holdEnabled: json['hold_enabled'] as bool? ?? false,
      holdStartDate: json['hold_start_date'] as String? ?? '',
      holdOffDate: json['hold_off_date'] as String? ?? '',
    );
  }
}

class HoldStatusModel {
  final bool success;
  final bool isHoldOn;
  final HoldStatusData data;

  HoldStatusModel({
    required this.success,
    required this.isHoldOn,
    required this.data,
  });

  factory HoldStatusModel.fromJson(Map<String, dynamic> json) {
    return HoldStatusModel(
      success: json['success'] as bool? ?? false,
      isHoldOn: json['is_hold_on'] as bool? ?? false,
      data: HoldStatusData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  static HoldStatusModel get permissive => HoldStatusModel(
        success: true,
        isHoldOn: false,
        data: HoldStatusData(
          holdEnabled: false,
          holdStartDate: '',
          holdOffDate: '',
        ),
      );
}
