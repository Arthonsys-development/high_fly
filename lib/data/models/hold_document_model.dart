class HoldDocument {
  final int id;
  final int hold;
  final String document;
  final String documentUrl;
  final String filetype;
  final String filetypeDisplay;
  final String description;
  final String createdAt;
  final String updatedAt;

  const HoldDocument({
    required this.id,
    required this.hold,
    required this.document,
    required this.documentUrl,
    required this.filetype,
    required this.filetypeDisplay,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HoldDocument.fromJson(Map<String, dynamic> json) {
    return HoldDocument(
      id: json['id'] ?? 0,
      hold: json['hold'] ?? 0,
      document: json['document']?.toString() ?? '',
      documentUrl: json['document_url']?.toString() ?? json['document']?.toString() ?? '',
      filetype: json['filetype']?.toString() ?? '',
      filetypeDisplay: json['filetype_display']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hold': hold,
      'document': document,
      'document_url': documentUrl,
      'filetype': filetype,
      'filetype_display': filetypeDisplay,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

