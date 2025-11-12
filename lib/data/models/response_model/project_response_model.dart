class Project {
  final int id;
  final String name;
  final String description;
  final String location;
  final String address;
  final String projectImage;
  final String status;
  final String? statusDisplay;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final int? totalPlotCount;
  final int? availablePlotCount;
  final String subAddress;
  final double? latitude;
  final double? longitude;
  final String? budget;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.address,
    required this.projectImage,
    required this.status,
    this.statusDisplay,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.totalPlotCount,
    this.availablePlotCount,
    required this.subAddress,
    this.latitude,
    this.longitude,
    this.budget,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names in the API response
    final id = json['id'] ?? json['project_id'] ?? 0;
    final name = json['name'] ?? json['project_name'] ?? json['title'] ?? '';
    final description = json['description'] ?? json['desc'] ?? '';
    final location = json['location'] ?? '';
    final address = json['address'] ?? '';
    final projectImage = json['project_image']?.toString() ?? json['photo']?.toString() ?? '';
    final status = json['status'] ?? json['project_status'] ?? 'Active';

    // Handle start_date and end_date (nullable)
    DateTime? startDate;
    DateTime? endDate;
    
    if (json['start_date'] != null) {
      try {
        startDate = DateTime.parse(json['start_date']);
      } catch (e) {
        startDate = null;
      }
    }
    
    if (json['end_date'] != null) {
      try {
        endDate = DateTime.parse(json['end_date']);
      } catch (e) {
        endDate = null;
      }
    }

    // Handle created_at date (nullable)
    DateTime? createdAt;
    try {
      if (json['created_at'] != null) {
        if (json['created_at'] is String) {
          createdAt = DateTime.parse(json['created_at']);
        } else if (json['created_at'] is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(json['created_at']);
        }
      } else if (json['date_created'] != null) {
        createdAt = DateTime.parse(json['date_created']);
      }
    } catch (e) {
      createdAt = null;
    }

    // Handle plot count fields - support both naming conventions
    final totalPlotCount = json['total_plots'] ?? json['total_plot_count'];
    final availablePlotCount = json['available_plots'] ?? json['available_plot_count'];
    
    // Handle sub_address field
    final subAddress = json['sub_address'] ?? '';
    
    // Handle status_display field
    final statusDisplay = json['status_display']?.toString();
    
    // Handle budget field
    final budget = json['budget']?.toString();

    // Handle latitude and longitude from location field (comma-separated)
    double? latitude;
    double? longitude;
    
    // Parse location field which contains "latitude,longitude"
    if (json['location'] != null && json['location'].toString().contains(',')) {
      try {
        final locationParts = json['location'].toString().split(',');
        if (locationParts.length >= 2) {
          latitude = double.tryParse(locationParts[0].trim());
          longitude = double.tryParse(locationParts[1].trim());
        }
      } catch (e) {
        latitude = null;
        longitude = null;
      }
    }
    
    // Fallback: Check for separate latitude and longitude fields
    if (latitude == null && json['latitude'] != null) {
      try {
        latitude = (json['latitude'] is String) 
            ? double.tryParse(json['latitude']) 
            : (json['latitude'] as num?)?.toDouble();
      } catch (e) {
        latitude = null;
      }
    }
    
    if (longitude == null && json['longitude'] != null) {
      try {
        longitude = (json['longitude'] is String) 
            ? double.tryParse(json['longitude']) 
            : (json['longitude'] as num?)?.toDouble();
      } catch (e) {
        longitude = null;
      }
    }

    return Project(
      id: id,
      name: name,
      description: description,
      location: location,
      address: address,
      projectImage: projectImage,
      status: status,
      statusDisplay: statusDisplay,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      totalPlotCount: totalPlotCount,
      availablePlotCount: availablePlotCount,
      subAddress: subAddress,
      latitude: latitude,
      longitude: longitude,
      budget: budget,
    );
  }

  Map<String, dynamic> toJson() {
    // Create location string in the format expected by the API
    String locationString = location;
    if (latitude != null && longitude != null) {
      locationString = '$latitude,$longitude';
    }
    
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': locationString,
      'address': address,
      'project_image': projectImage,
      'status': status,
      'status_display': statusDisplay,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'total_plots': totalPlotCount,
      'available_plots': availablePlotCount,
      'sub_address': subAddress,
      'latitude': latitude,
      'longitude': longitude,
      'budget': budget,
    };
  }
}