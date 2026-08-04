import 'response_model/project_response_model.dart';
import 'booking_document_model.dart';
import 'hold_plot_detail_model.dart';

class BookingListModel {
  final int id;
  final String plotCode;
  final String? plotSize;
  final String? plotArea;
  final String? plotPrice;
  final String? plotFacing;
  final Project? project;
  final String agentName;
  final String? agentEmail;
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
  final String? chequeCopy;
  final String? rtgsImage;
  final String? upiImage;
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
  final int plot;
  final int? groupId;
  final List<int> plotIds;
  final List<HoldPlotDetail> plotDetails;
  final int agent;
  final int customer;
  final String? cancelledBy;
  final String? fromHold;
  final String bookedAt;
  final List<BookingDocument> documents;
  final int documentCount;
  final String? pricePerSqYd;
  final String? loanBankName;
  final String? loanBankKey;
  final String? loanAmount;
  final String? saleableSize;
  final bool plcApplied;
  final double? plcPercentage;
  final String? roadWidthFront;
  final String? roadWidthBack;
  final String? roadWidthLeft;
  final String? roadWidthRight;

  const BookingListModel({
    required this.id,
    required this.plotCode,
    this.plotSize,
    this.plotArea,
    this.plotPrice,
    this.plotFacing,
    this.project,
    required this.agentName,
    this.agentEmail,
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
    this.chequeCopy,
    this.rtgsImage,
    this.upiImage,
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
    required this.plot,
    this.groupId,
    this.plotIds = const [],
    this.plotDetails = const [],
    required this.agent,
    required this.customer,
    this.cancelledBy,
    this.fromHold,
    required this.bookedAt,
    required this.documents,
    required this.documentCount,
    this.pricePerSqYd,
    this.loanBankName,
    this.loanBankKey,
    this.loanAmount,
    this.saleableSize,
    this.plcApplied = false,
    this.plcPercentage,
    this.roadWidthFront,
    this.roadWidthBack,
    this.roadWidthLeft,
    this.roadWidthRight,
  });

  List<int> get allPlotIds {
    if (plotIds.isNotEmpty) return plotIds;
    if (plotDetails.isNotEmpty) {
      return plotDetails.map((p) => p.id).where((id) => id > 0).toList();
    }
    if (plot > 0) return [plot];
    return const [];
  }

  bool get hasMultiplePlots => plotDetails.length > 1 || allPlotIds.length > 1;

  String get displayPlotLabel {
    if (plotDetails.isNotEmpty) {
      if (plotDetails.length == 1) return plotDetails.first.plotCode;
      final codes = plotDetails.map((p) => p.plotCode).where((c) => c.isNotEmpty);
      if (codes.isNotEmpty) {
        return '${plotDetails.length} plots (${codes.join(', ')})';
      }
      return '${plotDetails.length} plots';
    }
    return plotCode;
  }

  String get displayTotalAmount {
    if (plotDetails.length > 1) {
      double sum = 0;
      for (final p in plotDetails) {
        sum += double.tryParse(p.priceWithPlc) ?? double.tryParse(p.price) ?? 0;
      }
      if (sum > 0) return sum.toStringAsFixed(2);
    }
    return totalAmount;
  }

  bool matchesPlotSearch(String query) {
    final q = query.toLowerCase();
    if (plotCode.toLowerCase().contains(q)) return true;
    for (final p in plotDetails) {
      if (p.plotCode.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  factory BookingListModel.fromJson(Map<String, dynamic> json) {
    // Parse project if it exists
    Project? project;
    if (json['project'] != null && json['project'] is Map<String, dynamic>) {
      try {
        project = Project.fromJson(json['project'] as Map<String, dynamic>);
      } catch (e) {
        project = null;
      }
    }
    
    // Parse documents array
    List<BookingDocument> documents = [];
    if (json['document'] != null && json['document'] is List) {
      try {
        documents = (json['document'] as List)
            .map((doc) => BookingDocument.fromJson(doc as Map<String, dynamic>))
            .toList();
      } catch (e) {
        documents = [];
      }
    }

    List<int> plotIds = [];
    if (json['plot_ids'] is List) {
      plotIds = (json['plot_ids'] as List)
          .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
          .where((id) => id > 0)
          .toList();
    }

    List<HoldPlotDetail> plotDetails = [];
    if (json['plot_details'] is List) {
      try {
        plotDetails = (json['plot_details'] as List)
            .whereType<Map<String, dynamic>>()
            .map(HoldPlotDetail.fromJson)
            .toList();
      } catch (_) {
        plotDetails = [];
      }
    }
    
    return BookingListModel(
      id: json['id'] ?? 0,
      plotCode: json['plot_code'] ?? '',
      plotSize: json['plot_size']?.toString(),
      plotArea: json['plot_area']?.toString(),
      plotPrice: json['plot_price']?.toString(),
      plotFacing: json['plot_facing']?.toString(),
      project: project,
      agentName: json['agent_name'] ?? '',
      agentEmail: json['agent_email']?.toString(),
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
      chequeCopy: json['cheque_copy']?.toString(),
      rtgsImage: json['rtgs_image']?.toString(),
      upiImage: json['upi_image']?.toString(),
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
      plot: json['plot'] ?? 0,
      groupId: json['group_id'] is int
          ? json['group_id'] as int
          : int.tryParse('${json['group_id']}'),
      plotIds: plotIds,
      plotDetails: plotDetails,
      agent: json['agent'] ?? 0,
      customer: json['customer'] ?? 0,
      cancelledBy: json['cancelled_by']?.toString(),
      fromHold: json['from_hold']?.toString(),
      bookedAt: json['booked_at'] ?? '',
      documents: documents,
      documentCount: json['document_count'] ?? documents.length,
      pricePerSqYd: json['price_per_sq_yd']?.toString(),
      loanBankName: json['loan_bank_name']?.toString(),
      loanBankKey: json['loan_bank_key']?.toString(),
      loanAmount: json['loan_amount']?.toString(),
      saleableSize: json['saleable_size']?.toString(),
      plcApplied: json['plc_applied'] == true || json['plc_applied'] == 'true',
      plcPercentage: json['plc_percentage'] != null
          ? double.tryParse(json['plc_percentage'].toString())
          : null,
      roadWidthFront: _parseText(json['plot_road_width_front']),
      roadWidthBack: _parseText(json['plot_road_width_back']),
      roadWidthLeft: _parseText(json['plot_road_width_left']),
      roadWidthRight: _parseText(json['plot_road_width_right']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plot_code': plotCode,
      'plot_size': plotSize,
      'plot_area': plotArea,
      'plot_price': plotPrice,
      'plot_facing': plotFacing,
      'project': project?.toJson(),
      'agent_name': agentName,
      'agent_email': agentEmail,
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
      'cheque_copy': chequeCopy,
      'rtgs_image': rtgsImage,
      'upi_image': upiImage,
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
      'plot': plot,
      if (groupId != null) 'group_id': groupId,
      'plot_ids': plotIds,
      'plot_details': plotDetails
          .map((p) => {
                'id': p.id,
                'plot_code': p.plotCode,
                'project_name': p.projectName,
                'size_sq_yd': p.sizeSqYd,
                'total_area': p.totalArea,
                'price': p.price,
                'price_per_sq_yd': p.pricePerSqYd,
                'price_with_plc': p.priceWithPlc,
                'facing': p.facing,
                'status': p.status,
                'status_display': p.statusDisplay,
              })
          .toList(),
      'agent': agent,
      'customer': customer,
      'cancelled_by': cancelledBy,
      'from_hold': fromHold,
      'booked_at': bookedAt,
      'document': documents.map((doc) => doc.toJson()).toList(),
      'document_count': documentCount,
      if (pricePerSqYd != null) 'price_per_sq_yd': pricePerSqYd,
      if (loanBankName != null) 'loan_bank_name': loanBankName,
      if (loanBankKey != null) 'loan_bank_key': loanBankKey,
      if (loanAmount != null) 'loan_amount': loanAmount,
      if (saleableSize != null) 'saleable_size': saleableSize,
      'plc_applied': plcApplied,
      if (plcPercentage != null) 'plc_percentage': plcPercentage,
      if (roadWidthFront != null) 'plot_road_width_front': roadWidthFront,
      if (roadWidthBack != null) 'plot_road_width_back': roadWidthBack,
      if (roadWidthLeft != null) 'plot_road_width_left': roadWidthLeft,
      if (roadWidthRight != null) 'plot_road_width_right': roadWidthRight,
    };
  }

  static String? _parseText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

