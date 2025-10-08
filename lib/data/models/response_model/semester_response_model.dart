class SemesterItem {
  final int id;
  final String name;
  final DateTime semesterStartDate;
  final DateTime semesterEndDate;
  final String semesterLogo;
  final String price;
  final String buyButtonText;
  final bool isPurchase;
  final DateTime? createdAt;

  SemesterItem({
    required this.id,
    required this.name,
    required this.semesterStartDate,
    required this.semesterEndDate,
    required this.semesterLogo,
    required this.price,
    required this.buyButtonText,
    required this.isPurchase,
    this.createdAt,
  });

  factory SemesterItem.fromJson(Map<String, dynamic> json) {
    return SemesterItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      semesterStartDate: DateTime.tryParse(json['semester_start_date'] ?? '') ?? DateTime.now(),
      semesterEndDate: DateTime.tryParse(json['semester_end_date'] ?? '') ?? DateTime.now(),
      semesterLogo: json['semester_logo'] ?? '',
      price: json['price'] ?? '',
      buyButtonText: json['buy_button_text'] ?? 'Guess',
      isPurchase: json['is_purchase'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'semester_start_date': semesterStartDate.toIso8601String(),
      'semester_end_date': semesterEndDate.toIso8601String(),
      'semester_logo': semesterLogo,
      'price': price,
      'buy_button_text': buyButtonText,
      'is_purchase': isPurchase,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}