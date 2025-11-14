class BookingRequestModel {
  final int plot;
  final int agent;
  final int customer;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final String bookingType;
  final String bookingAmount;
  final String totalAmount;
  final String paymentMode;
  final String paymentReference;
  final String chequeNumber;
  final String chequeDate;
  final String paymentDetails;
  final String panCard;
  final String aadharCard;
  final String accountHolderName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
  final String bankContactNumber;
  final String status;
  final String remarks;
  final bool salaryIndividual;
  final String? salarySlipPath;
  final String? form16APath;
  final int? holdId;

  const BookingRequestModel({
    required this.plot,
    required this.agent,
    required this.customer,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.bookingType,
    required this.bookingAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.paymentReference,
    required this.chequeNumber,
    required this.chequeDate,
    required this.paymentDetails,
    required this.panCard,
    required this.aadharCard,
    required this.accountHolderName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
    required this.bankContactNumber,
    required this.status,
    required this.remarks,
    required this.salaryIndividual,
    this.salarySlipPath,
    this.form16APath,
    this.holdId,
  });

  Map<String, dynamic> toJson() {
    return {
      'plot': plot,
      'agent': agent,
      'customer': customer,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'customer_address': customerAddress,
      'booking_type': bookingType,
      'booking_amount': bookingAmount,
      'total_amount': totalAmount,
      'payment_mode': paymentMode,
      'payment_reference': paymentReference,
      'cheque_number': chequeNumber,
      'cheque_date': chequeDate,
      'payment_details': paymentDetails,
      'pan_card': panCard,
      'aadhar_card': aadharCard,
      'account_holder_name': accountHolderName,
      'branch_name': branchName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_type': accountType,
      'bank_contact_number': bankContactNumber,
      'status': status,
      'remarks': remarks,
      'salary_individual': salaryIndividual,
      if (salarySlipPath != null) 'salary_slip_path': salarySlipPath,
      if (form16APath != null) 'form_16a_path': form16APath,
      if (holdId != null) 'hold_id': holdId,
    };
  }

  // Convert to FormData for multipart requests
  Map<String, dynamic> toFormData() {
    final formData = toJson();
    
    // Keep file paths in FormData as they are local file paths
    // The backend will handle these as file references
    
    return formData;
  }
}
