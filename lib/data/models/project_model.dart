class Project {
  final String id;
  final String name;
  final List<Plot> plots;
  final int availablePlotCount;

  const Project({
    required this.id,
    required this.name,
    required this.plots,
    this.availablePlotCount = 0,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      plots: (json['plots'] as List<dynamic>)
          .map((plotJson) => Plot.fromJson(plotJson as Map<String, dynamic>))
          .toList(),
      availablePlotCount: json['available_plot_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plots': plots.map((plot) => plot.toJson()).toList(),
      'available_plot_count': availablePlotCount,
    };
  }
}

class Plot {
  final String id;
  final String plotNumber;
  final String projectId;
  final double area;
  final double price;
  final String dimensions;
  final String facing;
  final String remark;

  const Plot({
    required this.id,
    required this.plotNumber,
    required this.projectId,
    required this.area,
    required this.price,
    required this.dimensions,
    required this.facing,
    required this.remark,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    return Plot(
      id: json['id'] as String,
      plotNumber: json['plotNumber'] as String,
      projectId: json['projectId'] as String,
      area: (json['area'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      dimensions: json['dimensions'] as String,
      facing: json['facing'] as String,
      remark: json['remark'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plotNumber': plotNumber,
      'projectId': projectId,
      'area': area,
      'price': price,
      'dimensions': dimensions,
      'facing': facing,
      'remark': remark,
    };
  }

  String get displayText => '$plotNumber - ${area.toInt()} sq ft - ₹${price.toInt()}';
  String get displayTextOnPopup => '$dimensions - ${area.toInt()} sq ft - ₹${price.toInt()}';
}
