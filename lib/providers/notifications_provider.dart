import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../data/db.dart';

class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  bool _isGuest = false;

  /// Initialize for an authenticated user
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _isGuest = false;
    await loadNotifications();
  }

  /// Initialize for a guest (local storage only)
  Future<void> initializeGuest() async {
    _currentUserId = null;
    _isGuest = true;
    await loadNotifications();
  }

  /// Load all notifications (Supabase for auth users, local for guests)
  Future<void> loadNotifications() async {
    if (!_isGuest && _currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<Map<String, dynamic>> notifMaps;
      if (_isGuest) {
        notifMaps = await DB.getGuestNotifications();
      } else {
        notifMaps = await DB.getNotifications(_currentUserId!);
      }
      _notifications = notifMaps.map((n) => AppNotification.fromMap(n)).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      _errorMessage = 'Failed to load notifications: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get a specific notification by ID
  AppNotification? getNotification(String notificationId) {
    try {
      return _notifications.firstWhere((n) => n.id == notificationId);
    } catch (_) {
      return null;
    }
  }

  /// Get all notifications for a specific conversation (by related ID)
  List<AppNotification> getNotificationsForConversation(String conversationId) {
    return _notifications
        .where((n) => n.relatedId == conversationId && n.type == NotificationType.newMessage)
        .toList();
  }

  /// Get unread message notifications count for a specific conversation
  int getUnreadMessageNotificationsCount(String conversationId) {
    return _notifications
        .where((n) => n.relatedId == conversationId && 
                     n.type == NotificationType.newMessage && 
                     !n.isRead)
        .length;
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      if (_isGuest) {
        final all = await DB.getGuestNotifications();
        final updated = all.map((n) => n['id'] == notificationId ? {...n, 'is_read': true} : n).toList();
        await DB.saveGuestNotifications(updated);
      } else {
        await DB.markNotificationAsRead(notificationId);
      }
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to mark as read: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      if (_isGuest) {
        final all = await DB.getGuestNotifications();
        final updated = all.map((n) => {...n, 'is_read': true}).toList();
        await DB.saveGuestNotifications(updated);
      } else {
        if (_currentUserId == null) return;
        await DB.markAllNotificationsAsRead(_currentUserId!);
      }
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to mark all as read: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (_isGuest) {
        final all = await DB.getGuestNotifications();
        await DB.saveGuestNotifications(all.where((n) => n['id'] != notificationId).toList());
      } else {
        await DB.deleteNotification(notificationId);
      }
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        final wasUnread = !_notifications[index].isRead;
        _notifications.removeAt(index);
        if (wasUnread) _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to delete notification: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      if (_isGuest) {
        await DB.saveGuestNotifications([]);
      } else {
        if (_currentUserId == null) return;
        for (final notif in _notifications) {
          await DB.deleteNotification(notif.id);
        }
      }
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear notifications: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}