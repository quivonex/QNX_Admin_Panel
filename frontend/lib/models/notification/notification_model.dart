class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String time;
  bool isRead;  // ✅ final नाही, bool
  final String? route;
  final String? icon;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,  // ✅ default false
    this.route,
    this.icon,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? 'You have a new notification',
      time: json['time'] ?? 'Just now',
      isRead: json['isRead'] ?? false,
      route: json['route'],
      icon: json['icon'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time,
      'isRead': isRead,
      'route': route,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? time,
    bool? isRead,
    String? route,
    String? icon,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      route: route ?? this.route,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}