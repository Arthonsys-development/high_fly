import 'response_model/project_response_model.dart';
import 'hold_document_model.dart';
import 'hold_plot_detail_model.dart';

class HoldListModel {
  final int id;
  final String plotCode;
  final String? plotSize;
  final String? plotArea;
  final String? plotPrice;
  final String? plotFacing;
  final bool plc;
  final bool plcApplied;
  final double? plcPercentage;
  final Project? project;
  final String agentName;
  final String? agentEmail;
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
  final List<int> plotIds;
  final List<HoldPlotDetail> plotDetails;
  final int agent;
  final int customer;
  final List<HoldDocument> documents;
  final int documentCount;
  final String? saleableSize;

  const HoldListModel({
    required this.id,
    required this.plotCode,
    this.plotSize,
    this.plotArea,
    this.plotPrice,
    this.plotFacing,
    this.plc = false,
    this.plcApplied = false,
    this.plcPercentage,
    this.project,
    required this.agentName,
    this.agentEmail,
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
    this.plotIds = const [],
    this.plotDetails = const [],
    required this.agent,
    required this.customer,
    required this.documents,
    required this.documentCount,
    this.saleableSize,
  });

  /// All plot IDs for this hold (multi-plot aware).
  List<int> get allPlotIds {
    if (plotIds.isNotEmpty) return plotIds;
    if (plotDetails.isNotEmpty) {
      return plotDetails.map((p) => p.id).where((id) => id > 0).toList();
    }
    if (plot > 0) return [plot];
    return const [];
  }

  bool get hasMultiplePlots => plotDetails.length > 1 || allPlotIds.length > 1;

  /// Label for list cards: single code, comma-separated codes, or count.
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

  String? get aggregatedPlotPrice {
    if (plotDetails.isEmpty) return plotPrice;
    double sum = 0;
    for (final p in plotDetails) {
      sum += double.tryParse(p.price) ?? 0;
    }
    return sum > 0 ? sum.toStringAsFixed(2) : plotPrice;
  }

  double? get combinedSaleableSizeSqYd {
    if (plotDetails.isNotEmpty) {
      double sum = 0;
      for (final p in plotDetails) {
        sum += double.tryParse(p.sizeSqYd) ?? 0;
      }
      if (sum > 0) return sum;
    }
    if (saleableSize != null) return double.tryParse(saleableSize!);
    return null;
  }

  bool matchesPlotSearch(String query) {
    final q = query.toLowerCase();
    if (plotCode.toLowerCase().contains(q)) return true;
    for (final p in plotDetails) {
      if (p.plotCode.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  factory HoldListModel.fromJson(Map<String, dynamic> json) {
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
    List<HoldDocument> documents = [];
    if (json['document'] != null && json['document'] is List) {
      try {
        documents = (json['document'] as List)
            .map((item) => HoldDocument.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        documents = [];
      }
    }
    
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      final s = v.toString().toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
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

    return HoldListModel(
      id: json['id'] ?? 0,
      plotCode: json['plot_code'] ?? '',
      plotSize: json['plot_size']?.toString(),
      plotArea: json['plot_area']?.toString(),
      plotPrice: json['plot_price']?.toString(),
      plotFacing: json['plot_facing']?.toString(),
      plc: parseBool(json['plc']),
      plcApplied: parseBool(json['plc_applied']),
      plcPercentage: parseDouble(json['plc_percentage']),
      project: project,
      agentName: json['agent_name'] ?? '',
      agentEmail: json['agent_email']?.toString(),
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
      plotIds: plotIds,
      plotDetails: plotDetails,
      agent: json['agent'] ?? 0,
      customer: json['customer'] ?? 0,
      documents: documents,
      documentCount: json['document_count'] ?? documents.length,
      saleableSize: json['saleable_size']?.toString(),
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
      'plc': plc,
      'plc_applied': plcApplied,
      if (plcPercentage != null) 'plc_percentage': plcPercentage,
      'project': project?.toJson(),
      'agent_name': agentName,
      'agent_email': agentEmail,
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
      'document': documents.map((doc) => doc.toJson()).toList(),
      'document_count': documentCount,
      if (saleableSize != null) 'saleable_size': saleableSize,
    };
  }
}

