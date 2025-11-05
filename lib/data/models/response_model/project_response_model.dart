class Project {
  final int id;
  final String name;
  final String description;
  final String location;
  final String address;
  final String projectImage;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final int totalPlotCount;
  final int availablePlotCount;
  final String subAddress;
  final double? latitude;
  final double? longitude;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.address,
    required this.projectImage,
    required this.status,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.totalPlotCount,
    required this.availablePlotCount,
    required this.subAddress,
    this.latitude,
    this.longitude,
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

    // Handle created_at date
    DateTime createdAt;
    try {
      if (json['created_at'] != null) {
        if (json['created_at'] is String) {
          createdAt = DateTime.parse(json['created_at']);
        } else if (json['created_at'] is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(json['created_at']);
        } else {
          createdAt = DateTime.now();
        }
      } else if (json['date_created'] != null) {
        createdAt = DateTime.parse(json['date_created']);
      } else {
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }

    // Handle plot count fields
    final totalPlotCount = json['total_plot_count'] ?? 0;
    final availablePlotCount = json['available_plot_count'] ?? 0;
    
    // Handle sub_address field
    final subAddress = json['sub_address'] ?? '';

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
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      totalPlotCount: totalPlotCount,
      availablePlotCount: availablePlotCount,
      subAddress: subAddress,
      latitude: latitude,
      longitude: longitude,
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
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'total_plot_count': totalPlotCount,
      'available_plot_count': availablePlotCount,
      'sub_address': subAddress,
    };
  }
}