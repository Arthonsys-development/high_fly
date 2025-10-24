class HoldResponseModel {
  final int id;
  final int plot;
  final String plotCode;
  final String projectName;
  final int agent;
  final String agentName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String holdAmount;
  final String holdUntil;
  final String paymentMode;
  final String paymentModeDisplay;
  final String paymentReference;
  final String reraNumber;
  final String teamLeaderName;
  final String clientAadhar;
  final String accountHolderName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
  final String accountTypeDisplay;
  final String bankContactNumber;
  final String status;
  final String statusDisplay;
  final String remarks;
  final bool isExpired;
  final double timeRemaining;
  final String createdAt;
  final String updatedAt;

  const HoldResponseModel({
    required this.id,
    required this.plot,
    required this.plotCode,
    required this.projectName,
    required this.agent,
    required this.agentName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.holdAmount,
    required this.holdUntil,
    required this.paymentMode,
    required this.paymentModeDisplay,
    required this.paymentReference,
    required this.reraNumber,
    required this.teamLeaderName,
    required this.clientAadhar,
    required this.accountHolderName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
    required this.accountTypeDisplay,
    required this.bankContactNumber,
    required this.status,
    required this.statusDisplay,
    required this.remarks,
    required this.isExpired,
    required this.timeRemaining,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HoldResponseModel.fromJson(Map<String, dynamic> json) {
    return HoldResponseModel(
      id: json['id'] ?? 0,
      plot: json['plot'] ?? 0,
      plotCode: json['plot_code'] ?? '',
      projectName: json['project_name'] ?? '',
      agent: json['agent'] ?? 0,
      agentName: json['agent_name'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      holdAmount: json['hold_amount'] ?? '',
      holdUntil: json['hold_until'] ?? '',
      paymentMode: json['payment_mode'] ?? '',
      paymentModeDisplay: json['payment_mode_display'] ?? '',
      paymentReference: json['payment_reference'] ?? '',
      reraNumber: json['rera_number'] ?? '',
      teamLeaderName: json['team_leader_name'] ?? '',
      clientAadhar: json['client_aadhar'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountType: json['account_type'] ?? '',
      accountTypeDisplay: json['account_type_display'] ?? '',
      bankContactNumber: json['bank_contact_number'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      remarks: json['remarks'] ?? '',
      isExpired: json['is_expired'] ?? false,
      timeRemaining: (json['time_remaining'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
