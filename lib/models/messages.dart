enum MessageStatus { sent, delivered, read }

enum ConversationContext { listing, request }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.status,
  });

  String get timeLabel {
    final diff = DateTime.now().difference(sentAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) {
      final h = sentAt.hour.toString().padLeft(2, '0');
      final m = sentAt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${sentAt.month}/${sentAt.day}';
  }
}

class Conversation {
  final String id;
  final String participantId;
  final String participantName;
  final String participantInitials;
  final bool participantIsVerified;
  final String? participantPhone;
  final String? participantBarangay;
  final ConversationContext context;
  final String? relatedListingId;
  final String? relatedListingTitle;
  final List<ChatMessage> messages;
  final bool isMuted;

  const Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantInitials,
    required this.participantIsVerified,
    this.participantPhone,
    this.participantBarangay,
    required this.context,
    this.relatedListingId,
    this.relatedListingTitle,
    required this.messages,
    this.isMuted = false,
  });

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  int get unreadCount => messages
      .where((m) => m.status != MessageStatus.read && m.senderId != 'user_001')
      .length;

  bool get hasUnread => unreadCount > 0;

  String get lastMessagePreview {
    final msg = lastMessage;
    if (msg == null) return 'No messages yet';
    if (msg.text.length <= 50) return msg.text;
    return '${msg.text.substring(0, 50)}...';
  }

  String get lastActiveLabel => lastMessage?.timeLabel ?? '';
}
