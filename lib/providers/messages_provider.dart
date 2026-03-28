import 'package:flutter/foundation.dart';
import '../models/messages.dart';
import '../data/db.dart';

class MessagesProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  
  // Map to track merged conversation relationships: primaryID -> list of all related IDs
  final Map<String, List<String>> _mergedConversationIds = {};

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Conversation> get listingConversations => _conversations
      .where((c) => c.context == ConversationContext.listing)
      .toList();

  List<Conversation> get requestConversations => _conversations
      .where((c) => c.context == ConversationContext.request)
      .toList();

  /// Set active user without forcing a full conversation preload.
  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _conversations = [];
      _errorMessage = null;
      _mergedConversationIds.clear();
    }
  }

  /// Initialize the provider with a user ID and load conversations
  Future<void> initialize(String userId, {bool forceReload = false}) async {
    if (!forceReload && _currentUserId == userId && _conversations.isNotEmpty) {
      return;
    }

    setCurrentUser(userId);
    await loadConversations();
  }

  void _sortConversations() {
    _conversations.sort((a, b) {
      final aTime = a.lastMessage?.sentAt ?? DateTime(1970);
      final bTime = b.lastMessage?.sentAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
  }

  /// Merge conversations that are between the same two users for the same listing/context
  /// This handles the case where two conversations exist between the same participants
  /// (one from each user's perspective) and combines them into one.
  List<Conversation> _mergeDuplicateConversations(List<Conversation> conversations) {
    if (conversations.isEmpty || _currentUserId == null) return conversations;

    // Group conversations by context + related_listing_id since conversations between
    // the same two users for the same listing should be merged.
    final byKey = <String, List<Conversation>>{};

    for (final conv in conversations) {
      // Group by context + listing combination
      final key = '${conv.context.name}_${conv.relatedListingId ?? 'none'}';
      
      if (!byKey.containsKey(key)) {
        byKey[key] = [];
      }
      byKey[key]!.add(conv);
    }

    // For each group of potential duplicates, merge them
    final merged = <Conversation>[];
    for (final entry in byKey.entries) {
      final group = entry.value;
      if (group.length == 1) {
        merged.add(group.first);
      } else if (group.length > 1) {
        // Multiple conversations for the same context + listing
        // This happens when both users have created conversations from their perspective
        
        // Sort by latest message to keep the most active one
        group.sort((a, b) {
          final aTime = a.lastMessage?.sentAt ?? DateTime(1970);
          final bTime = b.lastMessage?.sentAt ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });

        // Combine all messages from all conversations
        final allMessages = <ChatMessage>[];
        for (final conv in group) {
          allMessages.addAll(conv.messages);
        }
        // Sort messages by sent time
        allMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

        // Use the first (most recent) conversation as base, but with merged messages
        final primary = group.first;
        
        // Determine the correct participant ID
        // The participant should be the OTHER user, not the current user
        String participantId = primary.participantId;
        String participantName = primary.participantName;
        String participantInitials = primary.participantInitials;
        bool participantIsVerified = primary.participantIsVerified;
        String? participantPhone = primary.participantPhone;
        String? participantBarangay = primary.participantBarangay;
        
        // If primary's participant is current user, get details from the other conversation
        if (primary.participantId == _currentUserId) {
          for (final conv in group) {
            if (conv.participantId != _currentUserId) {
              participantId = conv.participantId;
              participantName = conv.participantName;
              participantInitials = conv.participantInitials;
              participantIsVerified = conv.participantIsVerified;
              participantPhone = conv.participantPhone;
              participantBarangay = conv.participantBarangay;
              break;
            }
          }
        }
        
        merged.add(Conversation(
          id: primary.id,
          participantId: participantId,
          participantName: participantName,
          participantInitials: participantInitials,
          participantIsVerified: participantIsVerified,
          participantPhone: participantPhone,
          participantBarangay: participantBarangay,
          context: primary.context,
          relatedListingId: primary.relatedListingId,
          relatedListingTitle: primary.relatedListingTitle,
          messages: allMessages,
          isMuted: primary.isMuted,
        ));
        
        // Track all related conversation IDs for this merged conversation
        final allRelatedIds = group.map((c) => c.id).toList();
        _mergedConversationIds[primary.id] = allRelatedIds;
      }
    }

    return merged;
  }

  Conversation _copyConversationWithMessages(
    Conversation conversation,
    List<ChatMessage> messages,
  ) {
    return Conversation(
      id: conversation.id,
      participantId: conversation.participantId,
      participantName: conversation.participantName,
      participantInitials: conversation.participantInitials,
      participantIsVerified: conversation.participantIsVerified,
      participantPhone: conversation.participantPhone,
      participantBarangay: conversation.participantBarangay,
      context: conversation.context,
      relatedListingId: conversation.relatedListingId,
      relatedListingTitle: conversation.relatedListingTitle,
      messages: messages,
      isMuted: conversation.isMuted,
    );
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

      // Merge duplicate conversations (same context + listing)
      _conversations = _mergeDuplicateConversations(conversations);
      _sortConversations();
    } catch (e) {
      _errorMessage = 'Failed to load conversations: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh only one conversation's messages (faster than loading all chats)
  Future<void> refreshConversation(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    try {
      // For merged conversations, we need to check if there are other conversation IDs
      // with the same context + listing that need to be refreshed too
      final currentConv = _conversations[index];
      final allRelatedMessages = <ChatMessage>[];
      
      // Get all conversation IDs that share the same context + listing
      final relatedConvIds = _findRelatedConversationIds(currentConv);
      
      // Fetch messages from all related conversations
      for (final convId in relatedConvIds) {
        final msgMaps = await DB.getMessages(convId);
        final msgs = msgMaps.map((m) => ChatMessage.fromMap(m)).toList();
        allRelatedMessages.addAll(msgs);
      }
      
      // Sort all messages by sent time
      allRelatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      final refreshedMessages = allRelatedMessages;
      final current = _conversations[index];
      final currentLast = current.lastMessage?.id;
      final refreshedLast = refreshedMessages.isNotEmpty
          ? refreshedMessages.last.id
          : null;

      if (current.messages.length == refreshedMessages.length &&
          currentLast == refreshedLast) {
        return;
      }

      _conversations[index] = _copyConversationWithMessages(
        current,
        refreshedMessages,
      );
      _sortConversations();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh conversation: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Find all conversation IDs that have the same context + listing as the given conversation
  /// This is used to support merged conversations
  List<String> _findRelatedConversationIds(Conversation conv) {
    // First check if this is a merged conversation
    if (_mergedConversationIds.containsKey(conv.id)) {
      return _mergedConversationIds[conv.id]!;
    }
    
    // If not merged, return just this conversation ID
    return [conv.id];
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
      // Check if this is a merged conversation
      final relatedConvIds = _mergedConversationIds[conversationId];
      
      if (relatedConvIds != null && relatedConvIds.length > 1) {
        // For merged conversations, send to all related IDs
        // First, send to the primary conversation (which will create the notification)
        final result = await DB.sendMessage(
          conversationId: conversationId,
          senderId: _currentUserId!,
          text: text,
        );

        if (result == null) return false;

        // Then also send to other related conversations (for the other user's perspective)
        for (final convId in relatedConvIds) {
          if (convId != conversationId) {
            await DB.sendMessage(
              conversationId: convId,
              senderId: _currentUserId!,
              text: text,
            );
          }
        }

        // Update local state with messages from all related conversations
        final allMessages = <ChatMessage>[];
        for (final convId in relatedConvIds) {
          final msgMaps = await DB.getMessages(convId);
          final msgs = msgMaps.map((m) => ChatMessage.fromMap(m)).toList();
          allMessages.addAll(msgs);
        }
        allMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          _conversations[index] = _copyConversationWithMessages(
            _conversations[index],
            allMessages,
          );
          _sortConversations();
          notifyListeners();
        } else {
          await loadConversations();
        }
      } else {
        // Regular single conversation
        final result = await DB.sendMessage(
          conversationId: conversationId,
          senderId: _currentUserId!,
          text: text,
        );

        if (result == null) return false;

        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final updatedMessages = List<ChatMessage>.from(
            _conversations[index].messages,
          )..add(ChatMessage.fromMap(result));

          _conversations[index] = _copyConversationWithMessages(
            _conversations[index],
            updatedMessages,
          );
          _sortConversations();
          notifyListeners();
        } else {
          await loadConversations();
        }
      }

      return true;
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
        // If an initial message was passed on an existing chat, send it immediately
        if (initialMessage != null && initialMessage.isNotEmpty) {
          await sendMessage(
            conversationId: existing['id'] as String,
            text: initialMessage,
          );
          return getConversation(existing['id'] as String);
        }

        // Return the existing conversation
        final msgMaps = await DB.getMessages(existing['id'] as String);
        final messages = msgMaps.map((m) => ChatMessage.fromMap(m)).toList();
        final conversation = Conversation.fromMap(existing, messages);

        final index = _conversations.indexWhere((c) => c.id == conversation.id);
        if (index != -1) {
          _conversations[index] = conversation;
        } else {
          _conversations.add(conversation);
        }
        _sortConversations();
        notifyListeners();

        return conversation;
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
        final createdId = result['id'] as String;
        final createdMap = await DB.getConversationById(createdId);
        if (createdMap == null) return null;

        final msgMaps = await DB.getMessages(createdId);
        final messages = msgMaps.map((m) => ChatMessage.fromMap(m)).toList();
        final conversation = Conversation.fromMap(createdMap, messages);

        final index = _conversations.indexWhere((c) => c.id == createdId);
        if (index != -1) {
          _conversations[index] = conversation;
        } else {
          _conversations.add(conversation);
        }
        _sortConversations();
        notifyListeners();

        return conversation;
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

      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        final updatedMessages = _conversations[index].messages.map((m) {
          if (m.senderId != _currentUserId && m.status != MessageStatus.read) {
            return ChatMessage(
              id: m.id,
              senderId: m.senderId,
              text: m.text,
              sentAt: m.sentAt,
              status: MessageStatus.read,
            );
          }
          return m;
        }).toList();

        _conversations[index] = _copyConversationWithMessages(
          _conversations[index],
          updatedMessages,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  /// Mark messages in a conversation as read and also mark related notifications as read
  /// This links the unread message count to notifications to keep them in sync
  Future<void> markAsReadWithNotifications(
    String conversationId,
    Function(String) markNotificationRead,
  ) async {
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
