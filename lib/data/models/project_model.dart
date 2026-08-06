class Project {
  final String id;
  final String name;
  final List<Plot> plots;
  final int availablePlotCount;
  final String? payName;

  const Project({
    required this.id,
    required this.name,
    required this.plots,
    this.availablePlotCount = 0,
    this.payName,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawPlots = json['plots'];
    final parsedPlots = <Plot>[];
    if (rawPlots is List) {
      parsedPlots.addAll(
        rawPlots.whereType<Map<String, dynamic>>().map(Plot.fromJson),
      );
    } else if (rawPlots is Map<String, dynamic>) {
      parsedPlots.add(Plot.fromJson(rawPlots));
    }

    return Project(
      id: (json['id'] ?? json['project_id'] ?? '').toString(),
      name: (json['name'] ?? json['project_name'] ?? '').toString(),
      plots: parsedPlots,
      availablePlotCount: _parseInt(json['available_plot_count']) ?? 0,
      payName: _parsePayName(json['pay_name'] ?? json['payName']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plots': plots.map((plot) => plot.toJson()).toList(),
      'available_plot_count': availablePlotCount,
      'pay_name': payName,
    };
  }

  static String? _parsePayName(dynamic value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }
}

class Plot {
  final String id;
  final String plotNumber;
  final String projectId;
  final double area;
  final double price;
  final double? priceWithPlc;
  final double? saleableSize;
  final double? sizeSqYd;
  final double? width;
  final double? length;
  final String? roadWidthFront;
  final String? roadWidthBack;
  final String? roadWidthLeft;
  final String? roadWidthRight;
  final String? plotPosition;
  final String? plotShape;
  final String dimensions;
  final String facing;
  final String remark;
  final String status;
  final bool plc;
  final bool plcApplied;
  final double? plcPercentage;
  final bool hasActiveHold;
  final bool hasActiveBooking;
  final String? sitePlanUrl;
  final String? primaryImage;
  final String? createdAt;

  const Plot({
    required this.id,
    required this.plotNumber,
    required this.projectId,
    required this.area,
    required this.price,
    this.priceWithPlc,
    this.saleableSize,
    this.sizeSqYd,
    this.width,
    this.length,
    this.roadWidthFront,
    this.roadWidthBack,
    this.roadWidthLeft,
    this.roadWidthRight,
    this.plotPosition,
    this.plotShape,
    required this.dimensions,
    required this.facing,
    this.remark = '',
    this.status = '',
    this.plc = false,
    this.plcApplied = false,
    this.plcPercentage,
    this.hasActiveHold = false,
    this.hasActiveBooking = false,
    this.sitePlanUrl,
    this.primaryImage,
    this.createdAt,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    final width = _parseDouble(json['width']);
    final length = _parseDouble(json['length']);

    return Plot(
      id: (json['id'] ?? json['plot_id'] ?? '').toString(),
      plotNumber: (json['plotNumber'] ??
              json['plot_number'] ??
              json['plot_code'] ??
              '')
          .toString(),
      projectId:
          (json['projectId'] ?? json['project_id'] ?? json['project'] ?? '')
              .toString(),
      area: _parseDouble(json['total_area']) ??
          _parseDouble(json['area']) ??
          0.0,
      price: _parseDouble(json['price']) ?? 0.0,
      priceWithPlc: _parseDouble(json['priceWithPlc']) ??
          _parseDouble(json['price_with_plc']),
      saleableSize: _parseDouble(json['saleableSize']) ??
          _parseDouble(json['saleable_size']),
      sizeSqYd:
          _parseDouble(json['sizeSqYd']) ?? _parseDouble(json['size_sq_yd']),
      width: width,
      length: length,
      roadWidthFront: _parseText(json['plot_road_width_front']),
      roadWidthBack: _parseText(json['plot_road_width_back']),
      roadWidthLeft: _parseText(json['plot_road_width_left']),
      roadWidthRight: _parseText(json['plot_road_width_right']),
      plotPosition: _parseText(json['plot_position_display']) ??
          _parseText(json['plot_position']),
      plotShape: _parseText(json['plot_shape_display']) ??
          _parseText(json['plot_shape']),
      dimensions: _buildDimensions(
        width: width,
        length: length,
        fallback: json['dimensions']?.toString(),
      ),
      facing: (json['facing_display'] ?? json['facing'] ?? '').toString(),
      remark: (json['remark'] ?? json['plot_remark'] ?? json['status_display'] ?? '')
          .toString(),
      status: (json['status'] ?? '').toString(),
      plc: _parseBool(json['plc']),
      plcApplied:
          _parseBool(json['plcApplied']) || _parseBool(json['plc_applied']),
      plcPercentage: _parseDouble(json['plcPercentage']) ??
          _parseDouble(json['plc_percentage']),
      hasActiveHold: _parseBool(json['hasActiveHold']) ||
          _parseBool(json['has_active_hold']),
      hasActiveBooking: _parseBool(json['hasActiveBooking']) ||
          _parseBool(json['has_active_booking']),
      sitePlanUrl:
          json['sitePlanUrl']?.toString() ?? json['site_plan_url']?.toString(),
      primaryImage: json['primaryImage']?.toString() ??
          json['primary_image']?.toString(),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plotNumber': plotNumber,
      'projectId': projectId,
      'area': area,
      'price': price,
      'priceWithPlc': priceWithPlc,
      'saleableSize': saleableSize,
      'sizeSqYd': sizeSqYd,
      'width': width,
      'length': length,
      'plot_road_width_front': roadWidthFront,
      'plot_road_width_back': roadWidthBack,
      'plot_road_width_left': roadWidthLeft,
      'plot_road_width_right': roadWidthRight,
      'plot_position': plotPosition,
      'plot_shape': plotShape,
      'dimensions': dimensions,
      'facing': facing,
      'remark': remark,
      'plot_remark': remark,
      'status': status,
      'plc': plc,
      'plcApplied': plcApplied,
      'plcPercentage': plcPercentage,
      'hasActiveHold': hasActiveHold,
      'hasActiveBooking': hasActiveBooking,
      'sitePlanUrl': sitePlanUrl,
      'primaryImage': primaryImage,
      'createdAt': createdAt,
    };
  }

  double get effectivePrice => priceWithPlc ?? price;

  String get plotRemark => remark;

  /// Sum of [effectivePrice] for each plot (plot card "Combined Total").
  static double combinedEffectiveTotal(List<Plot> plots) {
    return plots.fold<double>(0, (sum, plot) => sum + plot.effectivePrice);
  }

  /// Formatted amount string for API/payment fields (no currency symbol).
  static String formatCombinedTotalAmount(List<Plot> plots) {
    final combinedTotal = combinedEffectiveTotal(plots);
    if (combinedTotal == 0) return '';
    return combinedTotal % 1 == 0
        ? combinedTotal.toStringAsFixed(0)
        : combinedTotal.toStringAsFixed(2);
  }

  String get displayText =>
      '$plotNumber - ${area.toStringAsFixed(2)} - ₹${effectivePrice.toStringAsFixed(2)}';
  String get displayTextOnPopup {
    final dimensionLabel = dimensions.isNotEmpty
        ? dimensions
        : area.toStringAsFixed(2);
    return '$dimensionLabel - ${area.toStringAsFixed(2)}';
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
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

  static String _buildDimensions({
    double? width,
    double? length,
    String? fallback,
  }) {
    String? format(double? value) {
      if (value == null || value <= 0) return null;
      return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    }

    final formattedWidth = format(width);
    final formattedLength = format(length);

    if (formattedWidth != null && formattedLength != null) {
      return '$formattedWidth x $formattedLength';
    }

    if (fallback != null) {
      return fallback;
    }

    if (formattedWidth != null || formattedLength != null) {
      final left = formattedWidth ?? '-';
      final right = formattedLength ?? '-';
      return '$left x $right';
    }

    return '';
  }
}
