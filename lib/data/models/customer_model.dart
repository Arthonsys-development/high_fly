class Customer {
  final int id;
  final String name;
  final String? email;
  final String phone;
  final String? location;
  final String? budget;
  final String? photo;
  final String? aadhar;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.location,
    this.budget,
    this.photo,
    this.aadhar,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int? ?? 0, // Handle case where id might be null
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String,
      location: json['location'] as String?,
      budget: json['budget'] as String?,
      photo: json['photo'] as String?,
      aadhar: json['aadhar'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'budget': budget,
      'photo': photo,
      'aadhar': aadhar,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, dynamic> toCreateRequestJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  String get displayText => '$name - $phone';
}
