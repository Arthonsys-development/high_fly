import 'project_model.dart';

class HoldPlotDetail {
  final int id;
  final String plotCode;
  final String projectName;
  final String? projectId;
  final String remark;
  final String sizeSqYd;
  final String totalArea;
  final String price;
  final String pricePerSqYd;
  final String priceWithPlc;
  final String? saleableSize;
  final String? width;
  final String? length;
  final String? roadWidthFront;
  final String? roadWidthBack;
  final String? roadWidthLeft;
  final String? roadWidthRight;
  final String? dimensions;
  final String? facing;
  final String status;
  final String statusDisplay;
  final bool plc;
  final bool plcApplied;
  final double? plcPercentage;
  final bool hasActiveHold;
  final bool hasActiveBooking;
  final String? sitePlanUrl;
  final String? primaryImage;
  final String? createdAt;

  const HoldPlotDetail({
    required this.id,
    required this.plotCode,
    required this.projectName,
    this.projectId,
    this.remark = '',
    required this.sizeSqYd,
    required this.totalArea,
    required this.price,
    required this.pricePerSqYd,
    required this.priceWithPlc,
    this.saleableSize,
    this.width,
    this.length,
    this.roadWidthFront,
    this.roadWidthBack,
    this.roadWidthLeft,
    this.roadWidthRight,
    this.dimensions,
    this.facing,
    required this.status,
    required this.statusDisplay,
    this.plc = false,
    this.plcApplied = false,
    this.plcPercentage,
    this.hasActiveHold = false,
    this.hasActiveBooking = false,
    this.sitePlanUrl,
    this.primaryImage,
    this.createdAt,
  });

  factory HoldPlotDetail.fromJson(Map<String, dynamic> json) {
    return HoldPlotDetail(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      plotCode: json['plot_code']?.toString() ?? '',
      projectName: json['project_name']?.toString() ?? '',
      projectId: json['project_id']?.toString(),
        remark: (json['remark'] ?? json['plot_remark'] ?? json['status_display'] ?? '')
          .toString(),
      sizeSqYd: json['size_sq_yd']?.toString() ?? '',
      totalArea: json['total_area']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      pricePerSqYd: json['price_per_sq_yd']?.toString() ?? '',
      priceWithPlc: json['price_with_plc']?.toString() ?? '',
      saleableSize: json['saleable_size']?.toString(),
      width: json['width']?.toString(),
      length: json['length']?.toString(),
      roadWidthFront: _parseText(json['plot_road_width_front']),
      roadWidthBack: _parseText(json['plot_road_width_back']),
      roadWidthLeft: _parseText(json['plot_road_width_left']),
      roadWidthRight: _parseText(json['plot_road_width_right']),
      dimensions: json['dimensions']?.toString(),
      facing: json['facing']?.toString(),
      status: json['status']?.toString() ?? '',
      statusDisplay: json['status_display']?.toString() ?? '',
      plc: _parseBool(json['plc']),
      plcApplied: _parseBool(json['plc_applied']),
      plcPercentage: _parseDouble(json['plc_percentage']),
      hasActiveHold: _parseBool(json['has_active_hold']),
      hasActiveBooking: _parseBool(json['has_active_booking']),
      sitePlanUrl: json['site_plan_url']?.toString(),
      primaryImage: json['primary_image']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Plot toPlot({
    bool? plc,
    bool? plcApplied,
    double? plcPercentage,
    String? projectId,
    String? roadWidthFront,
    String? roadWidthBack,
    String? roadWidthLeft,
    String? roadWidthRight,
  }) {
    return Plot.fromJson({
      'id': id,
      'plot_code': plotCode,
      'project_id': projectId ?? this.projectId ?? '',
      'plot_remark': remark,
      'remark': remark,
      'total_area': totalArea,
      'price': price,
      'price_with_plc': priceWithPlc,
      'saleable_size': saleableSize,
      'size_sq_yd': sizeSqYd,
      'width': width,
      'length': length,
      'plot_road_width_front': roadWidthFront ?? this.roadWidthFront,
      'plot_road_width_back': roadWidthBack ?? this.roadWidthBack,
      'plot_road_width_left': roadWidthLeft ?? this.roadWidthLeft,
      'plot_road_width_right': roadWidthRight ?? this.roadWidthRight,
      'dimensions': dimensions,
      'facing': facing ?? '',
      'status_display': statusDisplay,
      'status': status,
      'plc': plc ?? this.plc,
      'plc_applied': plcApplied ?? this.plcApplied,
      'plc_percentage': plcPercentage ?? this.plcPercentage,
      'has_active_hold': hasActiveHold,
      'has_active_booking': hasActiveBooking,
      'site_plan_url': sitePlanUrl,
      'primary_image': primaryImage,
      'created_at': createdAt,
    });
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static String? _parseText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
