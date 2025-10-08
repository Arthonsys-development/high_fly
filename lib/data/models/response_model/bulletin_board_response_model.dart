class BulletinBoardItem {
  final int id;
  final int semester;
  final String title;
  final String description;
  final String? logo;
  final bool isActive;
  final DateTime createdAt;

  BulletinBoardItem({
    required this.id,
    required this.semester,
    required this.title,
    required this.description,
    this.logo,
    required this.isActive,
    required this.createdAt,
  });

  factory BulletinBoardItem.fromJson(Map<String, dynamic> json) {
    return BulletinBoardItem(
      id: json['id'] ?? 0,
      semester: json['semester'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'],
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester': semester,
      'title': title,
      'description': description,
      'logo': logo,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to get plain text from HTML description
  String get plainDescription {
    return description
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}