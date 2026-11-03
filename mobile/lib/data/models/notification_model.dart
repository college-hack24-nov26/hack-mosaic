class NotificationModel {
  final String id;
  final String type; // 'alert', 'report_update', 'system'
  final String title;
  final String body;
  final String? alertId;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.alertId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'alert_id': alertId,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'system',
    title: json['title'] as String,
    body: json['body'] as String,
    alertId: json['alert_id'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    isRead: json['is_read'] as bool? ?? false,
  );
}
