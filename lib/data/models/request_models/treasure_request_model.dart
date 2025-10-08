class TreasureGuessRequest {
  final String semester;
  final String latitude;
  final String longitude;

  TreasureGuessRequest({
    required this.semester,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'semester': semester,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}