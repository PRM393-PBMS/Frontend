class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String content;
  final bool isRead;
  final String? type;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.content,
    required this.isRead,
    this.type,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    bool? isRead,
    String? type,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString(),
      title: json['title']?.toString() ?? 'Thông báo PBMS',
      content: json['content']?.toString() ?? '',
      isRead: json['isRead'] == true || json['isRead'] == 1,
      type: json['type']?.toString() ?? 'System',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'isRead': isRead,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
