class Project {
  final int id;
  final String name;
  final String location;
  final String description;
  final String status;
  final String projectPhoto;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.status,
    required this.projectPhoto,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names in the API response
    final id = json['id'] ?? json['project_id'] ?? 0;
    final name = json['name'] ?? json['project_name'] ?? json['title'] ?? '';
    final location = json['location'] ?? json['address'] ?? '';
    final description = json['description'] ?? json['desc'] ?? '';
    final status = json['status'] ?? json['project_status'] ?? 'Active';
    final projectPhoto = json['project_image']?.toString() ?? json['photo']?.toString() ?? '';

    // Handle different date formats
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

    return Project(
      id: id,
      name: name,
      location: location,
      description: description,
      status: status,
      projectPhoto: projectPhoto,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'status': status,
      'project_image': projectPhoto,
      'created_at': createdAt.toIso8601String(),
    };
  }
}