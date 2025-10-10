class HoldDetails {
  final String associateNameOrSelf;
  final String reraNumber;
  final String? teamLeaderName;
  final String clientAadhar;
  final String? additionalNotes;

  const HoldDetails({
    required this.associateNameOrSelf,
    required this.reraNumber,
    this.teamLeaderName,
    required this.clientAadhar,
    this.additionalNotes,
  });

  HoldDetails copyWith({
    String? associateNameOrSelf,
    String? reraNumber,
    String? teamLeaderName,
    String? clientAadhar,
    String? additionalNotes,
  }) {
    return HoldDetails(
      associateNameOrSelf: associateNameOrSelf ?? this.associateNameOrSelf,
      reraNumber: reraNumber ?? this.reraNumber,
      teamLeaderName: teamLeaderName ?? this.teamLeaderName,
      clientAadhar: clientAadhar ?? this.clientAadhar,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'associateNameOrSelf': associateNameOrSelf,
      'reraNumber': reraNumber,
      'teamLeaderName': teamLeaderName,
      'clientAadhar': clientAadhar,
      'additionalNotes': additionalNotes,
    };
  }

  factory HoldDetails.fromJson(Map<String, dynamic> json) {
    return HoldDetails(
      associateNameOrSelf: json['associateNameOrSelf'] ?? '',
      reraNumber: json['reraNumber'] ?? '',
      teamLeaderName: json['teamLeaderName'],
      clientAadhar: json['clientAadhar'] ?? '',
      additionalNotes: json['additionalNotes'],
    );
  }

  @override
  String toString() {
    return 'HoldDetails(associateNameOrSelf: $associateNameOrSelf, reraNumber: $reraNumber, teamLeaderName: $teamLeaderName, clientAadhar: $clientAadhar, additionalNotes: $additionalNotes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HoldDetails &&
        other.associateNameOrSelf == associateNameOrSelf &&
        other.reraNumber == reraNumber &&
        other.teamLeaderName == teamLeaderName &&
        other.clientAadhar == clientAadhar &&
        other.additionalNotes == additionalNotes;
  }

  @override
  int get hashCode {
    return associateNameOrSelf.hashCode ^
        reraNumber.hashCode ^
        teamLeaderName.hashCode ^
        clientAadhar.hashCode ^
        additionalNotes.hashCode;
  }
}
