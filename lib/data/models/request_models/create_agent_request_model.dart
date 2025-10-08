import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class CreateAgentRequest {
  final String projectId;
  final String visitName;
  final String phoneNumber;
  final String email;
  final String comments;
  final String? agentPhoto; // Changed to nullable String
  final File? agentPhotoFile; // Added file field for mobile
  final Uint8List? agentPhotoBytes; // Added bytes field for web

  CreateAgentRequest({
    required this.projectId,
    required this.visitName,
    required this.phoneNumber,
    required this.email,
    required this.comments,
    this.agentPhoto,
    this.agentPhotoFile,
    this.agentPhotoBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      "project_id": projectId,
      "visit_name": visitName,
      "phone_number": phoneNumber,
      "email": email,
      "comments": comments,
      if (agentPhoto != null) "visit_image": agentPhoto,
    };
  }

  // Method to convert to FormData for file uploads
  FormData toFormData() {
    final formData = FormData();

    formData.fields.add(MapEntry('project_id', projectId));
    formData.fields.add(MapEntry('visit_name', visitName));
    formData.fields.add(MapEntry('phone_number', phoneNumber));
    formData.fields.add(MapEntry('email', email));
    formData.fields.add(MapEntry('comments', comments));

    // Add profile photo file if available (mobile)
    if (agentPhotoFile != null) {
      formData.files.add(MapEntry(
        'visit_image',
        MultipartFile.fromFileSync(
          agentPhotoFile!.path,
          filename: 'visit_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ));
    }
    // Add profile photo bytes if available (web)
    else if (agentPhotoBytes != null) {
      formData.files.add(MapEntry(
        'visit_image',
        MultipartFile.fromBytes(
          agentPhotoBytes!,
          filename: 'visit_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ));
    }

    return formData;
  }
}