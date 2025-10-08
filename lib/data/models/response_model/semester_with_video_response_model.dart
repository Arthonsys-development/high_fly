class SemesterWithVideoItem {
  final int id;
  final String name;
  final DateTime? semesterStartDate;
  final DateTime? semesterEndDate;
  final String? semesterLogo;
  final String? price;
  final DateTime? createdAt;
  final List<SemesterVideoItem> semesterVideo;

  SemesterWithVideoItem({
    required this.id,
    required this.name,
    this.semesterStartDate,
    this.semesterEndDate,
    this.semesterLogo,
    this.price,
    this.createdAt,
    required this.semesterVideo,
  });

  factory SemesterWithVideoItem.fromJson(Map<String, dynamic> json) {
    return SemesterWithVideoItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      semesterStartDate: json['semester_start_date'] != null 
          ? DateTime.tryParse(json['semester_start_date']) 
          : null,
      semesterEndDate: json['semester_end_date'] != null 
          ? DateTime.tryParse(json['semester_end_date']) 
          : null,
      semesterLogo: json['semester_logo'],
      price: json['price'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      semesterVideo: (json['semester_video'] as List<dynamic>? ?? [])
          .map((item) => SemesterVideoItem.fromJson(item))
          .where((video) => video.isActive && video.isDashboard) // Filter active dashboard videos
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'semester_start_date': semesterStartDate?.toIso8601String(),
      'semester_end_date': semesterEndDate?.toIso8601String(),
      'semester_logo': semesterLogo,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'semester_video': semesterVideo.map((item) => item.toJson()).toList(),
    };
  }

  // Helper method to check if this semester has videos to display
  bool get hasVideos => semesterVideo.isNotEmpty;
}

class SemesterVideoItem {
  final int id;
  final int semester;
  final String title;
  final String message;
  final String url;
  final bool isActive;
  final bool isDashboard;
  final bool isSemester;
  final bool isPaid;
  final DateTime createdAt;

  SemesterVideoItem({
    required this.id,
    required this.semester,
    required this.title,
    required this.message,
    required this.url,
    required this.isActive,
    required this.isDashboard,
    required this.isSemester,
    required this.isPaid,
    required this.createdAt,
  });

  factory SemesterVideoItem.fromJson(Map<String, dynamic> json) {
    return SemesterVideoItem(
      id: json['id'] ?? 0,
      semester: json['semester'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      url: json['url'] ?? '',
      isActive: json['is_active'] ?? false,
      isDashboard: json['is_dashboard'] ?? false,
      isSemester: json['is_semester'] ?? false,
      isPaid: json['is_paid'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester': semester,
      'title': title,
      'message': message,
      'url': url,
      'is_active': isActive,
      'is_dashboard': isDashboard,
      'is_semester': isSemester,
      'is_paid': isPaid,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to get YouTube thumbnail URL
  String get thumbnailUrl {
    if (url.isNotEmpty) {
      return 'https://img.youtube.com/vi/$url/maxresdefault.jpg';
    }
    return '';
  }

  // Helper method to get YouTube video URL
  String get youtubeUrl {
    if (url.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$url';
    }
    return '';
  }
}