import 'package:dio/dio.dart';
import 'dart:io' show File;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data' show Uint8List;

class LoginTokenRequest {
  final String idToken;

  LoginTokenRequest({required this.idToken});

  Map<String, dynamic> toJson() {
    return {
      "id_token": idToken,
    };
  }
}

class RegisterRequest {
  final String idToken;
  final String fullName;
  final String phoneNumber;
  final String reraNumber;
  final String teamLeaderName;
  final String idNumber;
  final String? profilePhoto; // Changed to nullable String
  final File? profilePhotoFile; // Added file field for mobile
  final Uint8List? profilePhotoBytes; // Added bytes field for web

  RegisterRequest({
    required this.idToken,
    required this.fullName,
    required this.phoneNumber,
    required this.reraNumber,
    required this.teamLeaderName,
    required this.idNumber,
    this.profilePhoto,
    this.profilePhotoFile,
    this.profilePhotoBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      "id_token": idToken,
      "full_name": fullName,
      "phone_number": phoneNumber,
      "rera_number": reraNumber,
      "team_leader_name": teamLeaderName,
      "id_number": idNumber,
      if (profilePhoto != null) "profile_photo": profilePhoto,
    };
  }

  // Method to convert to FormData for file uploads
  FormData toFormData() {
    final formData = FormData();

    formData.fields.add(MapEntry('id_token', idToken));
    formData.fields.add(MapEntry('full_name', fullName));
    formData.fields.add(MapEntry('phone_number', phoneNumber));
    formData.fields.add(MapEntry('rera_number', reraNumber));
    formData.fields.add(MapEntry('team_leader_name', teamLeaderName));
    formData.fields.add(MapEntry('id_number', idNumber));

    // Add profile photo file if available (mobile)
    if (profilePhotoFile != null) {
      formData.files.add(MapEntry(
        'profile_photo',
        MultipartFile.fromFileSync(
          profilePhotoFile!.path,
          filename: 'profile_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ));
    }
    // Add profile photo bytes if available (web)
    else if (profilePhotoBytes != null) {
      formData.files.add(MapEntry(
        'profile_photo',
        MultipartFile.fromBytes(
          profilePhotoBytes!,
          filename: 'profile_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ));
    }

    return formData;
  }
}