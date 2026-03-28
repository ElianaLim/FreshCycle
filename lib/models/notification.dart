// Notification types for the app
enum NotificationType {
  newMessage,
  listingSaved,
  listingExpired,
  newListing,
  offerReceived,
  offerAccepted,
  offerRejected,
  pantryExpiringSoon,
  pantryExpiresTomorrow,
  pantryExpiresToday,
  pantryExpired,
}

// Notification model representing a single notification
class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? relatedId; // Can be listing ID, conversation ID, etc.
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'newMessage'),
        orElse: () => NotificationType.newMessage,
      ),
      title: map['title'] as String,
      body: map['body'] as String,
      relatedId: map['related_id'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper to get the appropriate icon for each notification type
  String get iconName {
    switch (type) {
      case NotificationType.newMessage:
        return 'chat';
      case NotificationType.listingSaved:
        return 'bookmark';
      case NotificationType.listingExpired:
        return 'schedule';
      case NotificationType.newListing:
        return 'new_releases';
      case NotificationType.offerReceived:
        return 'local_offer';
      case NotificationType.offerAccepted:
        return 'check_circle';
      case NotificationType.offerRejected:
        return 'cancel';
      case NotificationType.pantryExpiringSoon:
        return 'warning';
      case NotificationType.pantryExpiresTomorrow:
        return 'warning';
      case NotificationType.pantryExpiresToday:
        return 'warning';
      case NotificationType.pantryExpired:
        return 'cancel';
    }
  }

  // Get time label for display
  String get timeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}';
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}