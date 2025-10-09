class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final String budgetRange;
  final String? notes;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.budgetRange,
    this.notes,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      location: json['location'] as String,
      budgetRange: json['budgetRange'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'budgetRange': budgetRange,
      'notes': notes,
    };
  }

  String get displayText => '$name - $phone';
}
