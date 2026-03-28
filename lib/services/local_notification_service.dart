import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/pantry_item.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'pantry_expiry';
  static const _channelName = 'Pantry Expiry';
  static const _channelDesc = 'Alerts for items that are expiring or have expired';

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  /// Request permission from the user (iOS + Android 13+).
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Cancels all previously scheduled pantry notifications and reschedules
  /// them based on the current pantry list.
  static Future<void> schedulePantryNotifications(List<PantryItem> items) async {
    // Cancel all existing pantry notifications (ids 1000–1999)
    for (int i = 1000; i < 2000; i++) {
      await _plugin.cancel(i);
    }

    final now = tz.TZDateTime.now(tz.local);
    int id = 1000;

    for (final item in items) {
      if (id >= 2000) break; // cap at 1000 notifications

      final expiry = DateTime(
        item.computedExpiryDate.year,
        item.computedExpiryDate.month,
        item.computedExpiryDate.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      final daysLeft = expiry.difference(today).inDays;

      if (daysLeft < 0) {
        // Already expired — fire immediately (show right away)
        await _showNow(
          id: id++,
          title: 'Item expired',
          body: '"${item.name}" has expired. Consider removing it from your pantry.',
        );
      } else if (daysLeft == 0) {
        await _showNow(
          id: id++,
          title: 'Expires today',
          body: '"${item.name}" expires today. Use it before it\'s too late!',
        );
      } else {
        // Schedule at 8 AM on the relevant day(s)
        if (daysLeft == 1) {
          await _scheduleAt(
            id: id++,
            scheduledDate: _morningOf(expiry, now),
            title: 'Expires tomorrow',
            body: '"${item.name}" expires tomorrow.',
          );
        }
        if (daysLeft <= 3) {
          // Also fire a "expiring soon" notification today at 8 AM
          final todayMorning = _morningOf(today, now);
          if (todayMorning.isAfter(now)) {
            await _scheduleAt(
              id: id++,
              scheduledDate: todayMorning,
              title: 'Expiring soon',
              body: '"${item.name}" expires in $daysLeft day${daysLeft == 1 ? '' : 's'}.',
            );
          }
        }
      }
    }
  }

  static Future<void> _showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> _scheduleAt({
    required int id,
    required tz.TZDateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Returns 8:00 AM on the given [date] as a TZDateTime.
  /// If that time has already passed today, returns now + 1 minute
  /// so we don't silently drop the notification.
  static tz.TZDateTime _morningOf(DateTime date, tz.TZDateTime now) {
    final t = tz.TZDateTime(tz.local, date.year, date.month, date.day, 8);
    if (t.isBefore(now)) {
      return now.add(const Duration(minutes: 1));
    }
    return t;
  }
}
