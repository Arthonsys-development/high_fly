class LoginResponse {
  int? id;
  String? firstName;
  String? lastName;
  String? username;
  String? email;
  bool? isActive;
  String? token;
  String? message;
  bool? success;

  LoginResponse({
    this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.isActive,
    this.token,
    this.message,
    this.success,
  });

  LoginResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    username = json['username'];
    email = json['email'];
    isActive = json['is_active'];
    token = json['token'];
    message = json['message'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['username'] = username;
    data['email'] = email;
    data['is_active'] = isActive;
    data['token'] = token;
    data['message'] = message;
    data['success'] = success;
    return data;
  }
}

class RegisterResponse {
  int? id;
  String? firstName;
  String? lastName;
  String? username;
  String? email;
  bool? isActive;
  String? token;
  String? message;
  bool? success;

  RegisterResponse({
    this.id,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
    this.isActive,
    this.token,
    this.message,
    this.success,
  });

  RegisterResponse.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    username = json['username'];
    email = json['email'];
    isActive = json['is_active'];
    token = json['token'];
    message = json['message'];
    success = json['success'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    data['username'] = username;
    data['email'] = email;
    data['is_active'] = isActive;
    data['token'] = token;
    data['message'] = message;
    data['success'] = success;
    return data;
  }
}

class PasswordResetResponse {
  String? status;
  String? message;
  List<PasswordResetError>? errors;

  PasswordResetResponse({
    this.status,
    this.message,
    this.errors,
  });

  PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['errors'] != null) {
      errors = <PasswordResetError>[];
      json['errors'].forEach((v) {
        errors!.add(PasswordResetError.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (errors != null) {
      data['errors'] = errors!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PasswordResetError {
  String? field;
  List<String>? message;

  PasswordResetError({this.field, this.message});

  PasswordResetError.fromJson(Map<String, dynamic> json) {
    field = json['field'];
    message = json['message']?.cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['field'] = field;
    data['message'] = message;
    return data;
  }
}

class PasswordResetConfirmResponse {
  String? status;
  String? message;
  List<PasswordResetError>? errors;

  PasswordResetConfirmResponse({
    this.status,
    this.message,
    this.errors,
  });

  PasswordResetConfirmResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['errors'] != null) {
      errors = <PasswordResetError>[];
      json['errors'].forEach((v) {
        errors!.add(PasswordResetError.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (errors != null) {
      data['errors'] = errors!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}



class DeleteAccountResponse {
  String? status;
  String? message;
  bool? success;
  List<PasswordResetError>? errors;

  DeleteAccountResponse({
    this.status,
    this.message,
    this.success,
    this.errors,
  });

  DeleteAccountResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    success = json['success'];
    if (json['errors'] != null) {
      errors = <PasswordResetError>[];
      json['errors'].forEach((v) {
        errors!.add(PasswordResetError.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    data['success'] = success;
    if (errors != null) {
      data['errors'] = errors!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
