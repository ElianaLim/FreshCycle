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

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['sender_id'] as String,
      text: map['text'] as String,
      sentAt: DateTime.parse(map['sent_at'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'text': text,
      'sent_at': sentAt.toIso8601String(),
      'status': status.name,
    };
  }

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

  factory Conversation.fromMap(Map<String, dynamic> map, List<ChatMessage> messages) {
    return Conversation(
      id: map['id'] as String,
      participantId: map['participant_id'] as String,
      participantName: map['participant_name'] as String,
      participantInitials: map['participant_initials'] as String,
      participantIsVerified: map['participant_is_verified'] as bool? ?? false,
      participantPhone: map['participant_phone'] as String?,
      participantBarangay: map['participant_barangay'] as String?,
      context: ConversationContext.values.firstWhere(
        (e) => e.name == (map['context'] as String? ?? 'listing'),
        orElse: () => ConversationContext.listing,
      ),
      relatedListingId: map['related_listing_id'] as String?,
      relatedListingTitle: map['related_listing_title'] as String?,
      messages: messages,
      isMuted: map['is_muted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participant_id': participantId,
      'participant_name': participantName,
      'participant_initials': participantInitials,
      'participant_is_verified': participantIsVerified,
      'participant_phone': participantPhone,
      'participant_barangay': participantBarangay,
      'context': context.name,
      'related_listing_id': relatedListingId,
      'related_listing_title': relatedListingTitle,
      'is_muted': isMuted,
    };
  }

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
