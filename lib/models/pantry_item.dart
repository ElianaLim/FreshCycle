import '../models/listing.dart';

enum FoodType { perishable, nonPerishable }

class PantryItem {
  final String id;
  String name;
  String category;
  DateTime expiryDate;
  FoodType foodType;
  double? cost;
  UrgencyLevel urgency;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryDate,
    required this.foodType,
    this.cost,
    required this.urgency,
  });

  String get daysLeft {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final diff = expiry.difference(today).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff == 1) return 'Expires tomorrow';
    return '$diff days left';
  }
}
