class Visit {
  final int id;
  final int projectId;
  final String projectName;
  final String visitorName;
  final String phoneNumber;
  final String? email;
  final String agent;
  final String? comments;
  final String? visitorPhoto;
  final String visitDateTime;
  // final String visitTime;
  final String status;
  final String purpose;
  final String? clientName;
  final String? clientPhone;
  final String? clientInterestLevel;
  final bool isAtProjectLocation;
  final String? createdAt;
  final String? clientPhoto;

  Visit({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.visitorName,
    required this.phoneNumber,
    this.email,
    required this.agent,
    this.comments,
    this.visitorPhoto,
    required this.visitDateTime,
    // required this.visitTime,
    required this.status,
    required this.purpose,
    this.clientName,
    this.clientPhone,
    this.clientInterestLevel,
    this.isAtProjectLocation = false,
    this.createdAt,
    this.clientPhoto,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names in the API response
    final id = json['id'] ?? json['visit_id'] ?? 0;
    final projectId = json['project_id'] ?? json['project'] ?? 0;
    
    // Ensure all string fields are properly converted to String
    final projectName = (json['project_name'] ?? '').toString();
    final visitorName = (json['visitor_name'] ?? json['name'] ?? '').toString();
    final phoneNumber = (json['phone_number'] ?? json['phone'] ?? '').toString();
    final email = json['email']?.toString();
    final agent = (json['agent_name'] ?? json['agent'] ?? json['assigned_agent'] ?? '').toString();
    final comments = json['comments']?.toString();
    final visitorPhoto = json['visit_image']?.toString() ?? json['photo']?.toString();
    final purpose = (json['type'] ?? json['purpose'] ?? json['visit_purpose'] ?? '').toString();
    final clientName = json['client_name']?.toString();
    final clientPhone = json['client_phone']?.toString();
    final clientInterestLevel = json['client_interest_level']?.toString();
    final isAtProjectLocation = json['is_at_project_location'] == true || 
                                 json['is_at_project_location'] == 'true' ||
                                 (json['is_at_project_location'] is String && json['is_at_project_location'].toString().toLowerCase() == 'true');
    final createdAt = json['created_at']?.toString();
    final clientPhoto = json['client_photo']?.toString();

    // Handle date parsing
    // DateTime visitDate;
    // try {
    //   if (json['visit_datetime'] != null) {
    //     if (json['visit_datetime'] is String) {
    //       visitDate = DateTime.parse(json['visit_datetime']);
    //     } else if (json['visit_datetime'] is int) {
    //       visitDate = DateTime.fromMillisecondsSinceEpoch(json['visit_datetime']);
    //     } else {
    //       visitDate = DateTime.now();
    //     }
    //   } else if (json['date'] != null) {
    //     if (json['date'] is String) {
    //       visitDate = DateTime.parse(json['date']);
    //     } else if (json['date'] is int) {
    //       visitDate = DateTime.fromMillisecondsSinceEpoch(json['date']);
    //     } else {
    //       visitDate = DateTime.now();
    //     }
    //   } else {
    //     visitDate = DateTime.now();
    //   }
    // } catch (e) {
    //   visitDate = DateTime.now();
    // }

    // Handle time parsing - ensure it's a String
    final visitDateTime = (json['visit_datetime'] ?? json['time'] ?? '00:00').toString();

    // Handle status - ensure it's a String
    final status = (json['status'] ?? 'Pending').toString();

    return Visit(
      id: id is int ? id : (id is String ? int.tryParse(id) ?? 0 : 0),
      projectId: projectId is int ? projectId : (projectId is String ? int.tryParse(projectId) ?? 0 : 0),
      projectName: projectName,
      visitorName: visitorName,
      phoneNumber: phoneNumber,
      email: email,
      agent: agent,
      comments: comments,
      visitorPhoto: visitorPhoto,
      visitDateTime: visitDateTime,
      status: status,
      purpose: purpose,
      clientName: clientName,
      clientPhone: clientPhone,
      clientInterestLevel: clientInterestLevel,
      isAtProjectLocation: isAtProjectLocation,
      createdAt: createdAt,
      clientPhoto: clientPhoto,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'project_name': projectName,
      'visitor_name': visitorName,
      'phone_number': phoneNumber,
      'email': email,
      'agent': agent,
      'comments': comments,
      'visit_image': visitorPhoto,
      'visit_datetime': visitDateTime,
      'status': status,
      'purpose': purpose,
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_interest_level': clientInterestLevel,
      'is_at_project_location': isAtProjectLocation,
      'created_at': createdAt,
      'client_photo': clientPhoto,
    };
  }
}