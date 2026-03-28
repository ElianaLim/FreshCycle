import 'package:flutter/foundation.dart';
import '../models/messages.dart';
import '../models/notification.dart';
import '../data/db.dart';

class MessagesProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Conversation> get listingConversations =>
      _conversations.where((c) => c.context == ConversationContext.listing).toList();

  List<Conversation> get requestConversations =>
      _conversations.where((c) => c.context == ConversationContext.request).toList();

  /// Initialize the provider with a user ID and load conversations
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await loadConversations();
  }

  /// Load all conversations for the current user
  Future<void> loadConversations() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final convMaps = await DB.getConversations(_currentUserId!);
      final conversations = <Conversation>[];

      for (final convMap in convMaps) {
        final msgMaps = await DB.getMessages(convMap['id'] as String);
        final messages = msgMaps.map((m) => ChatMessage.fromMap(m)).toList();
        conversations.add(Conversation.fromMap(convMap, messages));
      }

      // Sort by last message time
      conversations.sort((a, b) {
        final aTime = a.lastMessage?.sentAt ?? DateTime(1970);
        final bTime = b.lastMessage?.sentAt ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      _conversations = conversations;
    } catch (e) {
      _errorMessage = 'Failed to load conversations: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get a specific conversation by ID
  Conversation? getConversation(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (_) {
      return null;
    }
  }

  /// Send a message in a conversation
  Future<bool> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    if (_currentUserId == null) return false;

    try {
      final result = await DB.sendMessage(
        conversationId: conversationId,
        senderId: _currentUserId!,
        text: text,
      );

      if (result != null) {
        // Reload conversations to get updated data
        await loadConversations();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Start a new conversation (or return existing)
  Future<Conversation?> startConversation({
    required String participantId,
    required String participantName,
    required String participantInitials,
    required bool participantIsVerified,
    String? participantPhone,
    String? participantBarangay,
    required ConversationContext context,
    String? relatedListingId,
    String? relatedListingTitle,
    String? initialMessage,
  }) async {
    if (_currentUserId == null) return null;

    try {
      // First try to find existing conversation
      final existing = await DB.findConversation(
        userId: _currentUserId!,
        participantId: participantId,
        relatedListingId: relatedListingId,
      );

      if (existing != null) {
        // Return the existing conversation
        final msgMaps = await DB.getMessages(existing['id'] as String);
        final messages = msgMaps.map((m) => ChatMessage.fromMap(m)).toList();
        return Conversation.fromMap(existing, messages);
      }

      // Create new conversation
      final result = await DB.createConversation(
        userId: _currentUserId!,
        participantId: participantId,
        participantName: participantName,
        participantInitials: participantInitials,
        participantIsVerified: participantIsVerified,
        participantPhone: participantPhone,
        participantBarangay: participantBarangay,
        context: context.name,
        relatedListingId: relatedListingId,
        relatedListingTitle: relatedListingTitle,
        initialMessage: initialMessage,
      );

      if (result != null) {
        // Reload conversations to get the new one
        await loadConversations();
        return _conversations.firstWhere(
          (c) => c.id == result['id'],
          orElse: () => _conversations.first,
        );
      }
      return null;
    } catch (e) {
      _errorMessage = 'Failed to start conversation: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Mark messages in a conversation as read
  Future<void> markAsRead(String conversationId) async {
    if (_currentUserId == null) return;

    try {
      await DB.markMessagesAsRead(conversationId, _currentUserId!);
      await loadConversations();
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  /// Mark messages in a conversation as read and also mark related notifications as read
  /// This links the unread message count to notifications to keep them in sync
  Future<void> markAsReadWithNotifications(String conversationId, Function(String) markNotificationRead) async {
    if (_currentUserId == null) return;

    try {
      // First mark messages as read
      await DB.markMessagesAsRead(conversationId, _currentUserId!);
      
      // Find all unread message notifications for this conversation and mark them as read
      final notifications = await DB.getNotifications(_currentUserId!);
      for (final notif in notifications) {
        if (notif['related_id'] == conversationId && 
            notif['type'] == 'newMessage' && 
            notif['is_read'] == false) {
          await DB.markNotificationAsRead(notif['id'] as String);
          // Also update local notification state if the provider is available
          markNotificationRead(notif['id'] as String);
        }
      }
      
      await loadConversations();
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}