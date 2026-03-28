import '../models/listing.dart';

enum FoodType { perishable, nonPerishable }

enum ExpiryType { absolute, relative }

class PantryItem {
  final String id;
  String name;
  String category;
  DateTime expiryDate;
  int relativeDays;
  ExpiryType expiryType;
  FoodType foodType;
  double? cost;
  UrgencyLevel urgency;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    this.relativeDays = 7,
    this.expiryType = ExpiryType.absolute,
    required this.foodType,
    this.cost,
    required this.urgency,
  });

  /// The effective expiry date — for relative items, recomputed from today.
  DateTime get computedExpiryDate {
    if (expiryType == ExpiryType.relative) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return today.add(Duration(days: relativeDays));
    }
    return expiryDate;
  }

  String get daysLeft {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expiry = DateTime(computedExpiryDate.year, computedExpiryDate.month, computedExpiryDate.day);
    final diff = expiry.difference(today).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return 'Expires tomorrow';
    return '$diff days left';
  }
}
