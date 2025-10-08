class CarouselItem {
  final int id;
  final String title;
  final String description;
  final String image;
  final bool isActive;
  final DateTime? createdAt;

  CarouselItem({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.isActive,
    this.createdAt,
  });

  factory CarouselItem.fromJson(Map<String, dynamic> json) {
    return CarouselItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}