class HoldRequestModel {
  final List<int> plotIds;
  final int customer;
  final int agent;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String reraNumber;
  final String teamLeaderName;
  final String clientAadhar;
  final double holdAmount;
  final String paymentMode;
  final String paymentReference;
  final String accountHolderName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
  final String bankContactNumber;
  final String holdUntil;
  final String remarks;
  final List<String>? documents;

  const HoldRequestModel({
    required this.plotIds,
    required this.customer,
    required this.agent,
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
    required this.holdUntil,
    required this.remarks,
    this.documents,
  });

  // plot_ids + documents: see BookingApiRepository.createHold — JSON body when
  // possible; multipart uses jsonEncode(plot_ids) and file parts for documents.
  Map<String, dynamic> toJson() {
    return {
      'plot_ids': plotIds,
      'customer': customer,
      'agent': agent,
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
      'hold_until': holdUntil,
      'remarks': remarks,
      if (documents != null && documents!.isNotEmpty) 'documents': documents,
    };
  }

  Map<String, dynamic> toFormData() {
    final formData = toJson();
    formData.remove('documents');
    formData.remove('plot_ids');
    return formData;
  }
}
