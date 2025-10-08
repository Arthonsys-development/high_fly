class AppInfoItem {
  final String title;
  final String content;

  AppInfoItem({
    required this.title,
    required this.content,
  });

  factory AppInfoItem.fromJson(Map<String, dynamic> json) {
    return AppInfoItem(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }

  // Helper method to get plain text from HTML content
  String get plainContent {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\r\n|\r|\n'), '\n') // Normalize line breaks
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up multiple line breaks
        .trim();
  }
}