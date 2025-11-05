class BookingListModel {
  final int id;
  final String plotCode;
  final String agentName;
  final String statusDisplay;
  final String createdAt;
  final String updatedAt;
  final String createdBy;
  final String updatedBy;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final bool salaryIndividual;
  final String bookingType;
  final String bookingAmount;
  final String totalAmount;
  final String paymentMode;
  final String paymentReference;
  final String chequeNumber;
  final String? chequeDate;
  final String paymentDetails;
  final String panCard;
  final String aadharCard;
  final String? bankStatement;
  final String? salarySlip;
  final String? form16a;
  final String? otherDocuments;
  final String accountHolderName;
  final String branchName;
  final String accountNumber;
  final String ifscCode;
  final String accountType;
  final String bankContactNumber;
  final String status;
  final String bookingDate;
  final String? cancelledAt;
  final String? cancellationReason;
  final String remarks;
  final int project;
  final int plot;
  final int agent;
  final int customer;
  final String? cancelledBy;
  final String? fromHold;
  final String bookedAt;

  const BookingListModel({
    required this.id,
    required this.plotCode,
    required this.agentName,
    required this.statusDisplay,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.salaryIndividual,
    required this.bookingType,
    required this.bookingAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.paymentReference,
    required this.chequeNumber,
    this.chequeDate,
    required this.paymentDetails,
    required this.panCard,
    required this.aadharCard,
    this.bankStatement,
    this.salarySlip,
    this.form16a,
    this.otherDocuments,
    required this.accountHolderName,
    required this.branchName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountType,
    required this.bankContactNumber,
    required this.status,
    required this.bookingDate,
    this.cancelledAt,
    this.cancellationReason,
    required this.remarks,
    required this.project,
    required this.plot,
    required this.agent,
    required this.customer,
    this.cancelledBy,
    this.fromHold,
    required this.bookedAt,
  });

  factory BookingListModel.fromJson(Map<String, dynamic> json) {
    return BookingListModel(
      id: json['id'] ?? 0,
      plotCode: json['plot_code'] ?? '',
      agentName: json['agent_name'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      updatedBy: json['updated_by']?.toString() ?? '',
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerAddress: json['customer_address'] ?? '',
      salaryIndividual: json['salary_individual'] ?? false,
      bookingType: json['booking_type'] ?? '',
      bookingAmount: json['booking_amount'] ?? '',
      totalAmount: json['total_amount'] ?? '',
      paymentMode: json['payment_mode'] ?? '',
      paymentReference: json['payment_reference'] ?? '',
      chequeNumber: json['cheque_number'] ?? '',
      chequeDate: json['cheque_date'],
      paymentDetails: json['payment_details'] ?? '',
      panCard: json['pan_card'] ?? '',
      aadharCard: json['aadhar_card'] ?? '',
      bankStatement: json['bank_statement'],
      salarySlip: json['salary_slip'],
      form16a: json['form_16a'],
      otherDocuments: json['other_documents'],
      accountHolderName: json['account_holder_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      accountType: json['account_type'] ?? '',
      bankContactNumber: json['bank_contact_number'] ?? '',
      status: json['status'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      cancelledAt: json['cancelled_at'],
      cancellationReason: json['cancellation_reason'],
      remarks: json['remarks'] ?? '',
      project: json['project'] ?? 0,
      plot: json['plot'] ?? 0,
      agent: json['agent'] ?? 0,
      customer: json['customer'] ?? 0,
      cancelledBy: json['cancelled_by']?.toString(),
      fromHold: json['from_hold']?.toString(),
      bookedAt: json['booked_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plot_code': plotCode,
      'agent_name': agentName,
      'status_display': statusDisplay,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'customer_address': customerAddress,
      'salary_individual': salaryIndividual,
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
      'bank_statement': bankStatement,
      'salary_slip': salarySlip,
      'form_16a': form16a,
      'other_documents': otherDocuments,
      'account_holder_name': accountHolderName,
      'branch_name': branchName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_type': accountType,
      'bank_contact_number': bankContactNumber,
      'status': status,
      'booking_date': bookingDate,
      'cancelled_at': cancelledAt,
      'cancellation_reason': cancellationReason,
      'remarks': remarks,
      'project': project,
      'plot': plot,
      'agent': agent,
      'customer': customer,
      'cancelled_by': cancelledBy,
      'from_hold': fromHold,
      'booked_at': bookedAt,
    };
  }
}

