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
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    // Handle different possible field names in the API response
    final id = json['id'] ?? json['visit_id'] ?? 0;
    final projectId = json['project_id'] ?? 0;
    
    // Ensure all string fields are properly converted to String
    final projectName = (json['project_name'] ?? json['project'] ?? '').toString();
    final visitorName = (json['visitor_name'] ?? json['name'] ?? '').toString();
    final phoneNumber = (json['phone_number'] ?? json['phone'] ?? '').toString();
    final email = json['email']?.toString();
    final agent = (json['agent'] ?? json['assigned_agent'] ?? '').toString();
    final comments = json['comments']?.toString();
    final visitorPhoto = json['visit_image']?.toString() ?? json['photo']?.toString();
    final purpose = (json['purpose'] ?? json['visit_purpose'] ?? '').toString();

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
    };
  }
}