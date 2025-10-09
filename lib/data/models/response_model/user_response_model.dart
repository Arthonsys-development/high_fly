class User {
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? profilePhoto;
  final bool isActive;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.profilePhoto,
    required this.isActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names in the API response
    final id = json['id'] ?? json['user_id'] ?? 0;
    final firstName = json['first_name'] ?? json['firstName'] ?? '';
    final lastName = json['last_name'] ?? json['lastName'] ?? '';
    final fullName = json['full_name'] ?? json['fullName'] ?? '$firstName $lastName'.trim();
    final email = json['email'] ?? '';
    final profilePhoto = json['profile_photo'] ?? json['profilePhoto'];
    final isActive = json['is_active'] ?? json['isActive'] ?? false;

    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: email,
      profilePhoto: profilePhoto,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'profile_photo': profilePhoto,
      'is_active': isActive,
    };
  }

  String get initials {
    final initials = <String>[];
    if (firstName.isNotEmpty) initials.add(firstName[0].toUpperCase());
    if (lastName.isNotEmpty) initials.add(lastName[0].toUpperCase());
    return initials.join('');
  }
}