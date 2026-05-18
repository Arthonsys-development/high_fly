class AnnouncementModel {
  final int id;
  final String title;
  final String description;
  final String senderName;
  final String status;
  final String sentAt;
  final String type;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.senderName,
    required this.status,
    required this.sentAt,
    required this.type,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      senderName: json['sender_name'] as String,
      status: json['status'] as String,
      sentAt: json['sent_at'] as String,
      type: json['type'] as String,
    );
  }
}

class TaskUpdateModel {
  final int id;
  final int task;
  final String taskTitle;
  final String message;
  final bool isRead;
  final String createdAt;
  final String type;

  TaskUpdateModel({
    required this.id,
    required this.task,
    required this.taskTitle,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.type,
  });

  factory TaskUpdateModel.fromJson(Map<String, dynamic> json) {
    return TaskUpdateModel(
      id: json['id'] as int,
      task: json['task'] as int,
      taskTitle: json['task_title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      createdAt: json['created_at'] as String,
      type: json['type'] as String,
    );
  }
}

class NotificationsModel {
  final List<AnnouncementModel> announcements;
  final List<TaskUpdateModel> taskUpdates;
  final int count;

  NotificationsModel({
    required this.announcements,
    required this.taskUpdates,
    required this.count,
  });

  factory NotificationsModel.fromJson(Map<String, dynamic> json) {
    return NotificationsModel(
      announcements: (json['announcements'] as List<dynamic>)
          .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      taskUpdates: (json['task_updates'] as List<dynamic>)
          .map((e) => TaskUpdateModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int,
    );
  }

  int get unreadCount {
    return taskUpdates.where((t) => !t.isRead).length + announcements.length;
  }
}
