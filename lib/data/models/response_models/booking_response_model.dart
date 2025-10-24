class BookingResponseModel {
  final int id;
  final int project;
  final int projectId;
  final String projectName;
  final int plot;
  final String plotCode;
  final int agent;
  final String agentName;
  final int customer;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final String bookingType;
  final String bookingTypeDisplay;
  final String bookingAmount;
  final String totalAmount;
  final String paymentMode;
  final String paymentModeDisplay;
  final String paymentReference;
  final String chequeNumber;
  final String chequeDate;
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
  final String statusDisplay;
  final String bookedAt;
  final String? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final String remarks;
  final String? fromHold;
  final String createdAt;
  final String updatedAt;

  const BookingResponseModel({
    required this.id,
    required this.project,
    required this.projectId,
    required this.projectName,
    required this.plot,
    required this.plotCode,
    required this.agent,
    required this.agentName,
    required this.customer,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerAddress,
    required this.bookingType,
    required this.bookingTypeDisplay,
    required this.bookingAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.paymentModeDisplay,
    required this.paymentReference,
    required this.chequeNumber,
    required this.chequeDate,
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
    required this.statusDisplay,
    required this.bookedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    required this.remarks,
    this.fromHold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    return BookingResponseModel(
      id: json['id'] ?? 0,
      project: json['project'] ?? 0,
      projectId: json['project_id'] ?? 0,
      projectName: json['project_name'] ?? '',
      plot: json['plot'] ?? 0,
      plotCode: json['plot_code'] ?? '',
      agent: json['agent'] ?? 0,
      agentName: json['agent_name'] ?? '',
      customer: json['customer'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerAddress: json['customer_address'] ?? '',
      bookingType: json['booking_type'] ?? '',
      bookingTypeDisplay: json['booking_type_display'] ?? '',
      bookingAmount: json['booking_amount'] ?? '',
      totalAmount: json['total_amount'] ?? '',
      paymentMode: json['payment_mode'] ?? '',
      paymentModeDisplay: json['payment_mode_display'] ?? '',
      paymentReference: json['payment_reference'] ?? '',
      chequeNumber: json['cheque_number'] ?? '',
      chequeDate: json['cheque_date'] ?? '',
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
      statusDisplay: json['status_display'] ?? '',
      bookedAt: json['booked_at'] ?? '',
      cancelledAt: json['cancelled_at'],
      cancelledBy: json['cancelled_by'],
      cancellationReason: json['cancellation_reason'],
      remarks: json['remarks'] ?? '',
      fromHold: json['from_hold'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}
