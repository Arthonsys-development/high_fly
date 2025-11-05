class HoldListModel {
  final int id;
  final String plotCode;
  final String agentName;
  final String statusDisplay;
  final bool isExpired;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String reraNumber;
  final String teamLeaderName;
  final String clientAadhar;
  final String holdAmount;
  final String paymentMode;
  final String paymentReference;
  final String accountHolderName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
  final String bankContactNumber;
  final String status;
  final String holdUntil;
  final String remarks;
  final int plot;
  final int agent;
  final int customer;

  const HoldListModel({
    required this.id,
    required this.plotCode,
    required this.agentName,
    required this.statusDisplay,
    required this.isExpired,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.reraNumber,
    required this.teamLeaderName,
    required this.clientAadhar,
    required this.holdAmount,
    required this.paymentMode,
    required this.paymentReference,
    required this.accountHolderName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
    required this.bankContactNumber,
    required this.status,
    required this.holdUntil,
    required this.remarks,
    required this.plot,
    required this.agent,
    required this.customer,
  });

  factory HoldListModel.fromJson(Map<String, dynamic> json) {
    return HoldListModel(
      id: json['id'] ?? 0,
      plotCode: json['plot_code'] ?? '',
      agentName: json['agent_name'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      isExpired: json['is_expired'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      updatedBy: json['updated_by']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      reraNumber: json['rera_number'] ?? '',
      teamLeaderName: json['team_leader_name'] ?? '',
      clientAadhar: json['client_aadhar'] ?? '',
      holdAmount: json['hold_amount'] ?? '',
      paymentMode: json['payment_mode'] ?? '',
      paymentReference: json['payment_reference'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountType: json['account_type'] ?? '',
      bankContactNumber: json['bank_contact_number'] ?? '',
      status: json['status'] ?? '',
      holdUntil: json['hold_until'] ?? '',
      remarks: json['remarks'] ?? '',
      plot: json['plot'] ?? 0,
      agent: json['agent'] ?? 0,
      customer: json['customer'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plot_code': plotCode,
      'agent_name': agentName,
      'status_display': statusDisplay,
      'is_expired': isExpired,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'rera_number': reraNumber,
      'team_leader_name': teamLeaderName,
      'client_aadhar': clientAadhar,
      'hold_amount': holdAmount,
      'payment_mode': paymentMode,
      'payment_reference': paymentReference,
      'account_holder_name': accountHolderName,
      'branch_name': branchName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_type': accountType,
      'bank_contact_number': bankContactNumber,
      'status': status,
      'hold_until': holdUntil,
      'remarks': remarks,
      'plot': plot,
      'agent': agent,
      'customer': customer,
    };
  }
}

