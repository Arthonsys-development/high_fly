class TermsConditionsResponse {
  final String title;
  final String content;

  TermsConditionsResponse({
    required this.title,
    required this.content,
  });

  factory TermsConditionsResponse.fromJson(Map<String, dynamic> json) {
    return TermsConditionsResponse(
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
}