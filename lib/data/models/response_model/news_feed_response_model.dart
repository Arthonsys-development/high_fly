class NewsFeedItem {
  final int id;
  final String text;
  final String date;
  final bool isActive;
  final DateTime? createdAt;

  NewsFeedItem({
    required this.id,
    required this.text,
    required this.date,
    required this.isActive,
    this.createdAt,
  });

  factory NewsFeedItem.fromJson(Map<String, dynamic> json) {
    return NewsFeedItem(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      date: json['date'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'date': date,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}