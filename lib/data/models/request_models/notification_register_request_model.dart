class NotificationRegisterRequestModel {
  final String registrationToken;
  final String deviceType;

  NotificationRegisterRequestModel({required this.registrationToken, required this.deviceType});

  Map<String, dynamic> toJson() {
    return {
      "registration_token": registrationToken,
      "device_type": deviceType,
    };
  }
}