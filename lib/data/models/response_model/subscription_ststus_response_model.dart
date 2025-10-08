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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['start_date'] = this.startDate;
    data['end_date'] = this.endDate;
    data['transaction_id'] = this.transactionId;
    return data;
  }
}
