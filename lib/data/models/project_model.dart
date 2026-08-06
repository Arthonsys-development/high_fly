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
  final String? projectName;
  final double area;
  final double price;
  final double? priceWithPlc;
  final double? pricePerSqYd;
  final double? pricePerSqYdWithPlc;
  final double? saleableSize;
  final double? sizeSqYd;
  final double? width;
  final double? length;
  final String? roadWidthFront;
  final String? roadWidthBack;
  final String? roadWidthLeft;
  final String? roadWidthRight;
  final String? jdaPatta;
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
  final int imagesCount;
  final String? createdAt;

  const Plot({
    required this.id,
    required this.plotNumber,
    required this.projectId,
    this.projectName,
    required this.area,
    required this.price,
    this.priceWithPlc,
    this.pricePerSqYd,
    this.pricePerSqYdWithPlc,
    this.saleableSize,
    this.sizeSqYd,
    this.width,
    this.length,
    this.roadWidthFront,
    this.roadWidthBack,
    this.roadWidthLeft,
    this.roadWidthRight,
    this.jdaPatta,
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
    this.imagesCount = 0,
    this.createdAt,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    final width = _parseDouble(json['width']);
    final length = _parseDouble(json['length']);
    final wlDimensions =
        _parseText(json['plot_wl']) ?? _parseText(json['wl']);

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
      projectName: _parseText(json['project_name'] ?? json['projectName']),
      area: _parseDouble(json['total_area']) ??
          _parseDouble(json['area']) ??
          0.0,
      price: _parseDouble(json['price']) ?? 0.0,
      priceWithPlc: _parseDouble(json['priceWithPlc']) ??
          _parseDouble(json['price_with_plc']),
      pricePerSqYd: _parseDouble(json['pricePerSqYd']) ??
          _parseDouble(json['price_per_sq_yd']),
      pricePerSqYdWithPlc: _parseDouble(json['pricePerSqYdWithPlc']) ??
          _parseDouble(json['price_per_sq_yd_with_plc']),
      saleableSize: _parseDouble(json['saleableSize']) ??
          _parseDouble(json['saleable_size']),
      sizeSqYd:
          _parseDouble(json['sizeSqYd']) ?? _parseDouble(json['size_sq_yd']),
      width: width,
      length: length,
      roadWidthFront: _parseRoadWidth(json, 'front'),
      roadWidthBack: _parseRoadWidth(json, 'back'),
      roadWidthLeft: _parseRoadWidth(json, 'left'),
      roadWidthRight: _parseRoadWidth(json, 'right'),
      jdaPatta: _parseText(json['plot_jda_patta']) ??
          _parseText(json['jda_patta']),
      plotPosition: _formatLabel(
            _parseText(json['plot_position_display']) ??
                _parseText(json['plot_position']),
          ),
      plotShape: _formatLabel(
            _parseText(json['plot_shape_display']) ??
                _parseText(json['plot_shape']),
          ),
      dimensions: wlDimensions ??
          _buildDimensions(
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
      imagesCount: _parseInt(json['images_count'] ?? json['imagesCount']) ?? 0,
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plotNumber': plotNumber,
      'projectId': projectId,
      'project_name': projectName,
      'area': area,
      'price': price,
      'priceWithPlc': priceWithPlc,
      'price_per_sq_yd': pricePerSqYd,
      'price_per_sq_yd_with_plc': pricePerSqYdWithPlc,
      'saleableSize': saleableSize,
      'sizeSqYd': sizeSqYd,
      'width': width,
      'length': length,
      'road_width_front': roadWidthFront,
      'road_width_back': roadWidthBack,
      'road_width_left': roadWidthLeft,
      'road_width_right': roadWidthRight,
      'plot_road_width_front': roadWidthFront,
      'plot_road_width_back': roadWidthBack,
      'plot_road_width_left': roadWidthLeft,
      'plot_road_width_right': roadWidthRight,
      'jda_patta': jdaPatta,
      'plot_jda_patta': jdaPatta,
      'plot_position': plotPosition,
      'plot_shape': plotShape,
      'dimensions': dimensions,
      'wl': dimensions,
      'plot_wl': dimensions,
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
      'images_count': imagesCount,
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
      '$plotNumber - ${formatMeasure(area)} - ₹${effectivePrice.toStringAsFixed(2)}';
  String get displayTextOnPopup {
    final dimensionLabel = dimensions.isNotEmpty
        ? dimensions
        : formatMeasure(area);
    return '$dimensionLabel - ${formatMeasure(area)}';
  }

  /// Format area / size values as floats (e.g. 600.0), matching API style.
  static String formatMeasure(num? value) {
    if (value == null) return '';
    final d = value.toDouble();
    if (d == d.roundToDouble()) {
      return d.toStringAsFixed(1);
    }
    final fixed = d.toStringAsFixed(2);
    return fixed.endsWith('0') ? fixed.substring(0, fixed.length - 1) : fixed;
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
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  /// Converts API keys like `t_point` / `normal` into display labels: "T Point" / "Normal".
  static String? _formatLabel(String? value) {
    if (value == null) return null;
    final words = value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .toList();
    if (words.isEmpty) return null;
    return words.join(' ');
  }

  /// Prefer plot-specific road width, fall back to generic road_width_*.
  static String? _parseRoadWidth(Map<String, dynamic> json, String side) {
    return _parseText(json['plot_road_width_$side']) ??
        _parseText(json['road_width_$side']);
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
