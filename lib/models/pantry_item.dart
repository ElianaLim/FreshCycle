import 'package:flutter/material.dart';
import '../models/listing.dart';

enum ExpiryType { absolute, relative }

class PantryItem {
  final String id;
  final String deviceId;
  String name;
  String category;
  DateTime expiryDate;
  int relativeDays;
  ExpiryType expiryType;
  double? cost;
  UrgencyLevel urgency;

  PantryItem({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.category,
    required this.expiryDate,
    this.relativeDays = 7,
    this.expiryType = ExpiryType.absolute,
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

  IconData get categoryIcon {
    switch (category) {
      case 'Produce':
        return Icons.eco_outlined;
      case 'Dairy':
        return Icons.egg_outlined;
      case 'Bakery':
        return Icons.bakery_dining_outlined;
      case 'Meat & fish':
        return Icons.set_meal_outlined;
      case 'Meals & leftovers':
        return Icons.lunch_dining_outlined;
      case 'Snacks':
        return Icons.cookie_outlined;
      case 'Beverages':
        return Icons.local_drink_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  /// Build from a Supabase row map.
  factory PantryItem.fromMap(Map<String, dynamic> map) {
    final expiryTypeStr = map['expiry_type'] as String? ?? 'absolute';
    final expiryType = expiryTypeStr == 'relative' ? ExpiryType.relative : ExpiryType.absolute;

    final urgencyStr = map['urgency'] as String? ?? 'safe';
    final urgency = _urgencyFromString(urgencyStr);

    return PantryItem(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Other',
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      relativeDays: map['relative_days'] as int? ?? 7,
      expiryType: expiryType,
      cost: (map['cost'] as num?)?.toDouble(),
      urgency: urgency,
    );
  }

  /// Convert to a map for Supabase insert/update.
  /// Pass [userId] when the user is authenticated; leave null for guests.
  Map<String, dynamic> toMap({String? userId}) {
    return {
      'id': id,
      'device_id': deviceId,
      if (userId != null) 'user_id': userId,
      'name': name,
      'category': category,
      'expiry_type': expiryType == ExpiryType.relative ? 'relative' : 'absolute',
      'relative_days': relativeDays,
      'expiry_date': computedExpiryDate.toIso8601String(),
      'cost': cost,
      // urgency is computed by the DB trigger — no need to send it
    };
  }

  static UrgencyLevel _urgencyFromString(String s) {
    switch (s) {
      case 'critical':
        return UrgencyLevel.critical;
      case 'soon':
        return UrgencyLevel.soon;
      default:
        return UrgencyLevel.safe;
    }
  }
}