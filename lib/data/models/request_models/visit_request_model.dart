import 'package:dio/dio.dart';
import 'dart:io' show File;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data' show Uint8List;

class CreateVisitRequest {
  final String projectId;
  final String agentId;
  final String visitorName;
  final String reraNumber;
  final String teamLeaderName;
  final String dateTime;
  final String lat;
  final String long;
  final String type; // Visit type
  // final String phoneNumber;
  // final String email;
  final String? comments;
  final File? visitorPhoto; // For mobile
  final File? visitorPhotoFile; // For mobile
  final Uint8List? visitorPhotoBytes; // For we

  CreateVisitRequest({
    required this.projectId,
    required this.agentId,
    required this.visitorName,
    required this.reraNumber,
    required this.teamLeaderName,
    // required this.phoneNumber,
    // required this.email,
    required this.lat,
    required this.long,
    required this.dateTime,
    required this.type,
    this.comments,
    this.visitorPhoto,
    this.visitorPhotoFile,
    this.visitorPhotoBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      "project": projectId,
      "agent": agentId,
      "visitor_name": visitorName,
      "rera_number": reraNumber,
      "team_leader_name": teamLeaderName,
      "type": type,
      // "client_phone": phoneNumber,
      // "client_email": email,
      "visit_datetime": dateTime,
      "location_latitude": lat,
      "location_longitude": long,
      if (comments != null) "comments": comments,
      if (visitorPhoto != null) "visitor_photo": visitorPhoto,
    };
  }

  // Method to convert to FormData for file uploads
  FormData toFormData() {
    final formData = FormData();

    formData.fields.add(MapEntry('project', projectId.toString()));
    formData.fields.add(MapEntry('agent', agentId.toString()));
    formData.fields.add(MapEntry('visitor_name', visitorName));
    formData.fields.add(MapEntry('rera_number', reraNumber));
    formData.fields.add(MapEntry('team_leader_name', teamLeaderName));
    // formData.fields.add(MapEntry('client_phone', phoneNumber));
    // formData.fields.add(MapEntry('client_email', email));
    formData.fields.add(MapEntry('visit_datetime', dateTime));
    formData.fields.add(MapEntry('location_latitude', lat));
    formData.fields.add(MapEntry('location_longitude', long));
    formData.fields.add(MapEntry('type', type));
    if (comments != null) {
      formData.fields.add(MapEntry('comments', comments!));
    }

    // Add visitor photo file if available (mobile)
    if (visitorPhotoFile != null) {
      formData.files.add(MapEntry(
        'visit_image',
        MultipartFile.fromFileSync(
          visitorPhotoFile!.path,
          filename: 'visitor_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ));
    }
    // Add visitor photo bytes if available (web)
    else if (visitorPhotoBytes != null) {
      formData.files.add(MapEntry(
        'visit_image',
        MultipartFile.fromBytes(
          visitorPhotoBytes!,
          filename: 'visitor_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      ));
    }
    return formData;
  }
}