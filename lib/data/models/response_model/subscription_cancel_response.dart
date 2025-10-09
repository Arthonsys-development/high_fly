class SubscriptionCancelModel {
  bool? success;
  String? message;
  String? subscriptionId;
  String? status;

  SubscriptionCancelModel(
      {this.success, this.message, this.subscriptionId, this.status});

  SubscriptionCancelModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    subscriptionId = json['subscription_id'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    data['subscription_id'] = subscriptionId;
    data['status'] = status;
    return data;
  }
}
