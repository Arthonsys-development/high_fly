class TreasureGuessResponse {
  final int id;
  final int semester;
  final String latitude;
  final String longitude;
  final int order;

  TreasureGuessResponse({
    required this.id,
    required this.semester,
    required this.latitude,
    required this.longitude,
    required this.order,
  });

  factory TreasureGuessResponse.fromJson(Map<String, dynamic> json) {
    return TreasureGuessResponse(
      id: json['id'] ?? 0,
      semester: json['semester'] ?? 0,
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester': semester,
      'latitude': latitude,
      'longitude': longitude,
      'order': order,
    };
  }
}