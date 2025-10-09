class ProfileResponseData {
  int? id;
  User? user;
  String? phoneNumber;
  String? reraNumber;
  String? idNumber;
  String? profileImage;
  String? idProofImage;
  String? teamLeaderName;
  String? status;
  bool? isVerified;
  String? address;
  int? experienceYears;
  String? specialization;
  String? commissionRate;
  String? fullName;
  String? createdAt;

  ProfileResponseData(
      {this.id,
        this.user,
        this.phoneNumber,
        this.reraNumber,
        this.idNumber,
        this.profileImage,
        this.idProofImage,
        this.teamLeaderName,
        this.status,
        this.isVerified,
        this.address,
        this.experienceYears,
        this.specialization,
        this.commissionRate,
        this.fullName,
        this.createdAt});

  ProfileResponseData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
    phoneNumber = json['phone_number'];
    reraNumber = json['rera_number'];
    idNumber = json['id_number'];
    profileImage = json['profile_image'];
    idProofImage = json['id_proof_image'];
    teamLeaderName = json['team_leader_name'];
    status = json['status'];
    isVerified = json['is_verified'];
    address = json['address'];
    experienceYears = json['experience_years'];
    specialization = json['specialization'];
    commissionRate = json['commission_rate'];
    fullName = json['full_name'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['phone_number'] = phoneNumber;
    data['rera_number'] = reraNumber;
    data['id_number'] = idNumber;
    data['profile_image'] = profileImage;
    data['id_proof_image'] = idProofImage;
    data['team_leader_name'] = teamLeaderName;
    data['status'] = status;
    data['is_verified'] = isVerified;
    data['address'] = address;
    data['experience_years'] = experienceYears;
    data['specialization'] = specialization;
    data['commission_rate'] = commissionRate;
    data['full_name'] = fullName;
    data['created_at'] = createdAt;
    return data;
  }
}

class User {
  int? id;
  String? email;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  bool? isPhoneVerified;
  String? profileImage;

  User(
      {this.id,
        this.email,
        this.firstName,
        this.lastName,
        this.phoneNumber,
        this.isPhoneVerified,
        this.profileImage});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    phoneNumber = json['phone_number'];
    isPhoneVerified = json['is_phone_verified'];
    profileImage = json['profile_image'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['email'] = email;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['phone_number'] = phoneNumber;
    data['is_phone_verified'] = isPhoneVerified;
    data['profile_image'] = profileImage;
    return data;
  }
}
