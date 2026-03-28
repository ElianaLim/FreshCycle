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

  /// Initialize the provider with a user ID and load notifications
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await loadNotifications();
  }

  /// Load all notifications for the current user
  Future<void> loadNotifications() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final notifMaps = await DB.getNotifications(_currentUserId!);
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
      await DB.markNotificationAsRead(notificationId);
      
      // Update local state
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
    if (_currentUserId == null) return;

    try {
      await DB.markAllNotificationsAsRead(_currentUserId!);
      
      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
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
      await DB.deleteNotification(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        final wasUnread = !_notifications[index].isRead;
        _notifications.removeAt(index);
        if (wasUnread) {
          _unreadCount = _notifications.where((n) => !n.isRead).length;
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to delete notification: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    if (_currentUserId == null) return;

    try {
      for (final notif in _notifications) {
        await DB.deleteNotification(notif.id);
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