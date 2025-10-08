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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['message'] = this.message;
    data['subscription_id'] = this.subscriptionId;
    data['status'] = this.status;
    return data;
  }
}
