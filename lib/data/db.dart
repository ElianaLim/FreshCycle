import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DB {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call DB.init() first.');
    }
    return _client!;
  }

  static Future<void> init() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final key = dotenv.env['SUPABASE_KEY'] ?? '';

    await Supabase.initialize(url: url, anonKey: key);

    _client = Supabase.instance.client;
  }

  // Register new user - insert into profiles table
  static Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
    required String number,
  }) async {
    try {
      // First, create auth user
      final authResponse = await _client!.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return null;
      }

      // Then insert into profiles table
      final userId = authResponse.user!.id;
      final initials = _getInitials(name);

      // Set the session to establish auth context for RLS
      final session = authResponse.session;
      final refreshToken = session?.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client!.auth.setSession(refreshToken);
      }

      await _client!.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
        'initials': initials,
        'created_at': DateTime.now().toIso8601String(),
        'phone_number': number,
        'points': 0,
      });

      return {
        'id': userId,
        'name': name,
        'email': email,
        'initials': initials,
        'phone_number': number,
        'points': 0,
      };
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Login user - simple email/password check against profiles table
  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // First, authenticate with Supabase Auth
      final authResponse = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return null;
      }

      // Get user profile from profiles table
      final response = await _client!
          .from('profiles')
          .select()
          .eq('id', authResponse.user!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    await _client!.auth.signOut();
  }

  // Change password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First verify the current password by trying to sign in
      final verifyResult = await _client!.auth.signInWithPassword(
        email: _client!.auth.currentUser?.email ?? '',
        password: currentPassword,
      );

      if (verifyResult.user == null) {
        return false;
      }

      // Now update the password
      final response = await _client!.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response.user != null;
    } catch (e) {
      print('Change password error: $e');
      return false;
    }
  }

  // Get current user
  static Map<String, dynamic>? getCurrentUser() {
    final user = _client!.auth.currentUser;
    return user != null ? {'id': user.id, 'email': user.email} : null;
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateProfile({
    required String userId,
    String? name,
    String? initials,
    String? phoneNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) {
        updateData['name'] = name;
        if (initials == null) {
          updateData['initials'] = _getInitials(name);
        }
      }
      if (initials != null) {
        updateData['initials'] = initials;
      }
      if (phoneNumber != null) {
        updateData['phone_number'] = phoneNumber;
      }

      if (updateData.isEmpty) return true;

      await _client!.from('profiles').update(updateData).eq('id', userId);
      return true;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
  
  // Returns a stable device ID, generating one on first call
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_id';
    String? id = prefs.getString(key);
    if (id == null) {
      id = uuid.v4();
      await prefs.setString(key, id);
    }
    return id;
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  // ── Conversations & Messages ─────────────────────────────────────────────────

  /// Get all conversations for a user
  static Future<List<Map<String, dynamic>>> getConversations(
    String userId,
  ) async {
    try {
      final response = await _client!
          .from('conversations')
          .select()
          .or('user_id.eq.$userId,participant_id.eq.$userId')
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Get conversations error: $e');
      return [];
    }
  }

  /// Get one conversation by id
  static Future<Map<String, dynamic>?> getConversationById(
    String conversationId,
  ) async {
    try {
      final response = await _client!
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Get conversation by id error: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId,
  ) async {
    try {
      final response = await _client!
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('sent_at', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Get messages error: $e');
      return [];
    }
  }

  /// Send a message (creates message and updates conversation)
  static Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      final messageId = uuid.v4();
      final now = DateTime.now().toIso8601String();

      // Insert message
      await _client!.from('messages').insert({
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'text': text,
        'sent_at': now,
        'status': 'sent',
      });

      // Update conversation's updated_at
      await _client!
          .from('conversations')
          .update({'updated_at': now})
          .eq('id', conversationId);

      return {
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'text': text,
        'sent_at': now,
        'status': 'sent',
      };
    } catch (e) {
      print('Send message error: $e');
      return null;
    }
  }

  /// Create a new conversation
  static Future<Map<String, dynamic>?> createConversation({
    required String userId,
    required String participantId,
    required String participantName,
    required String participantInitials,
    required bool participantIsVerified,
    String? participantPhone,
    String? participantBarangay,
    required String context,
    String? relatedListingId,
    String? relatedListingTitle,
    String? initialMessage,
  }) async {
    try {
      final conversationId = uuid.v4();
      final now = DateTime.now().toIso8601String();

      // Create conversation
      await _client!.from('conversations').insert({
        'id': conversationId,
        'user_id': userId,
        'participant_id': participantId,
        'participant_name': participantName,
        'participant_initials': participantInitials,
        'participant_is_verified': participantIsVerified,
        'participant_phone': participantPhone,
        'participant_barangay': participantBarangay,
        'context': context,
        'related_listing_id': relatedListingId,
        'related_listing_title': relatedListingTitle,
        'created_at': now,
        'updated_at': now,
        'is_muted': false,
      });

      // If there's an initial message, create it
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await sendMessage(
          conversationId: conversationId,
          senderId: userId,
          text: initialMessage,
        );
      }

      return {
        'id': conversationId,
        'user_id': userId,
        'participant_id': participantId,
      };
    } catch (e) {
      print('Create conversation error: $e');
      return null;
    }
  }

  /// Find existing conversation with a participant for a listing/request
  static Future<Map<String, dynamic>?> findConversation({
    required String userId,
    required String participantId,
    String? relatedListingId,
  }) async {
    try {
      var query = _client!
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .eq('participant_id', participantId);

      if (relatedListingId != null) {
        query = query.eq('related_listing_id', relatedListingId);
      }

      final response = await query.maybeSingle();
      return response;
    } catch (e) {
      print('Find conversation error: $e');
      return null;
    }
  }

  /// Mark messages as read
  static Future<void> markMessagesAsRead(
    String conversationId,
    String userId,
  ) async {
    try {
      await _client!
          .from('messages')
          .update({'status': 'read'})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);
    } catch (e) {
      print('Mark messages as read error: $e');
    }
  }

  // ── Notifications ─────────────────────────────────────────────────

  /// Get all notifications for a user
  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    try {
      final response = await _client!
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Get notifications error: $e');
      return [];
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await _client!
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);
      final list = response as List;
      return list.length;
    } catch (e) {
      print('Get unread notification count error: $e');
      return 0;
    }
  }

  /// Create a new notification
  static Future<Map<String, dynamic>?> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    try {
      final notificationId = uuid.v4();
      final now = DateTime.now().toIso8601String();

      await _client!.from('notifications').insert({
        'id': notificationId,
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'related_id': relatedId,
        'is_read': false,
        'created_at': now,
      });

      return {
        'id': notificationId,
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'related_id': relatedId,
        'is_read': false,
        'created_at': now,
      };
    } catch (e) {
      print('Create notification error: $e');
      return null;
    }
  }

  /// Mark a notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client!
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Mark notification as read error: $e');
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _client!
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Mark all notifications as read error: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _client!.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      print('Delete notification error: $e');
    }
  }

  /// Create notification for new message in conversation
  static Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String conversationId,
    String? listingTitle,
  }) async {
    final listingContext = listingTitle != null ? ' about "$listingTitle"' : '';
    await createNotification(
      userId: recipientId,
      type: 'newMessage',
      title: 'New message',
      body: '$senderName sent you a message$listingContext',
      relatedId: conversationId,
    );
  }

  /// Create notification when someone saves a listing
  static Future<void> notifyListingSaved({
    required String sellerId,
    required String saverName,
    required String listingId,
    required String listingTitle,
  }) async {
    await createNotification(
      userId: sellerId,
      type: 'listingSaved',
      title: 'Listing saved',
      body: '$saverName saved your listing "$listingTitle"',
      relatedId: listingId,
    );
  }

  /// Create notification when someone makes an offer
  static Future<void> notifyOfferReceived({
    required String sellerId,
    required String offererName,
    required String listingId,
    required String listingTitle,
    required double offerAmount,
  }) async {
    await createNotification(
      userId: sellerId,
      type: 'offerReceived',
      title: 'New offer',
      body:
          '$offererName offered ₱${offerAmount.toStringAsFixed(0)} for "$listingTitle"',
      relatedId: listingId,
    );
  }

  /// Create notification when offer is accepted
  static Future<void> notifyOfferAccepted({
    required String offererId,
    required String listingTitle,
    required String listingId,
  }) async {
    await createNotification(
      userId: offererId,
      type: 'offerAccepted',
      title: 'Offer accepted!',
      body: 'Your offer for "$listingTitle" was accepted',
      relatedId: listingId,
    );
  }

  /// Create notification when offer is rejected
  static Future<void> notifyOfferRejected({
    required String offererId,
    required String listingTitle,
    required String listingId,
  }) async {
    await createNotification(
      userId: offererId,
      type: 'offerRejected',
      title: 'Offer declined',
      body: 'Your offer for "$listingTitle" was declined',
      relatedId: listingId,
    );
  }

  // ── Guest (local) notifications ──────────────────────────────────────────────

  static const _guestNotifKey = 'guest_notifications';

  static Future<List<Map<String, dynamic>>> getGuestNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestNotifKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> saveGuestNotifications(List<Map<String, dynamic>> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestNotifKey, jsonEncode(notifications));
  }

  static Future<void> addGuestNotification(Map<String, dynamic> notification) async {
    final all = await getGuestNotifications();
    all.insert(0, notification);
    await saveGuestNotifications(all);
  }

  static Future<void> notifyGuestPantryExpiry({
    required String type,
    required String title,
    required String body,
    required String itemId,
  }) async {
    try {
      final all = await getGuestNotifications();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

      final alreadySent = all.any((n) =>
          n['type'] == type &&
          n['related_id'] == itemId &&
          (n['created_at'] as String).compareTo(startOfDay) >= 0);

      if (alreadySent) return;

      await addGuestNotification({
        'id': uuid.v4(),
        'user_id': '',
        'type': type,
        'title': title,
        'body': body,
        'related_id': itemId,
        'is_read': false,
        'created_at': today.toIso8601String(),
      });
    } catch (e) {
      print('Guest pantry expiry notification error: $e');
    }
  }

  /// Create a pantry expiry notification only if one with the same
  /// [type] + [relatedId] (item id) hasn't already been sent today.
  static Future<void> notifyPantryExpiry({
    required String userId,
    required String type,
    required String title,
    required String body,
    required String itemId,
  }) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();

      final existing = await _client!
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('type', type)
          .eq('related_id', itemId)
          .gte('created_at', startOfDay)
          .maybeSingle();

      if (existing != null) return; // already sent today

      await createNotification(
        userId: userId,
        type: type,
        title: title,
        body: body,
        relatedId: itemId,
      );
    } catch (e) {
      print('Pantry expiry notification error: $e');
    }
  }
}

// UUID generator
class uuid {
  static final _rng = Random.secure();

  static String v4() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
