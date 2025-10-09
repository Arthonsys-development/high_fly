class SubscriptionStatusModel {
  String? status;
  String? startDate;
  String? endDate;
  String? transactionId;

  SubscriptionStatusModel(
      {this.status, this.startDate, this.endDate, this.transactionId});

  SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    transactionId = json['transaction_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['transaction_id'] = transactionId;
    return data;
  }
}
