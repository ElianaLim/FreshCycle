import '../data/db.dart';
import '../models/pantry_item.dart';

class PantryNotificationService {
  static Future<void> checkAndNotify(List<PantryItem> items) async {
    final authUser = DB.getCurrentUser();
    final isGuest = authUser == null;
    final userId = authUser?['id'] as String?;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final item in items) {
      final expiry = DateTime(
        item.computedExpiryDate.year,
        item.computedExpiryDate.month,
        item.computedExpiryDate.day,
      );
      final daysLeft = expiry.difference(today).inDays;

      if (daysLeft < 0) {
        await _notify(
          isGuest: isGuest,
          userId: userId,
          type: 'pantryExpired',
          title: 'Item expired',
          body: '"${item.name}" has expired. Consider removing it from your pantry.',
          itemId: item.id,
        );
      } else if (daysLeft == 0) {
        await _notify(
          isGuest: isGuest,
          userId: userId,
          type: 'pantryExpiresToday',
          title: 'Expires today',
          body: '"${item.name}" expires today. Use it before it\'s too late!',
          itemId: item.id,
        );
      } else if (daysLeft == 1) {
        await _notify(
          isGuest: isGuest,
          userId: userId,
          type: 'pantryExpiresTomorrow',
          title: 'Expires tomorrow',
          body: '"${item.name}" expires tomorrow.',
          itemId: item.id,
        );
      } else if (daysLeft <= 3) {
        await _notify(
          isGuest: isGuest,
          userId: userId,
          type: 'pantryExpiringSoon',
          title: 'Expiring soon',
          body: '"${item.name}" expires in $daysLeft days.',
          itemId: item.id,
        );
      }
    }
  }

  static Future<void> _notify({
    required bool isGuest,
    required String? userId,
    required String type,
    required String title,
    required String body,
    required String itemId,
  }) async {
    if (isGuest) {
      await DB.notifyGuestPantryExpiry(
        type: type,
        title: title,
        body: body,
        itemId: itemId,
      );
    } else {
      await DB.notifyPantryExpiry(
        userId: userId!,
        type: type,
        title: title,
        body: body,
        itemId: itemId,
      );
    }
  }
}
