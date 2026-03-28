enum ListingType { selling, requesting }

enum UrgencyLevel { safe, soon, critical }

class SellerProfile {
  final String id;
  final String name;
  final String initials;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final String barangay;

  const SellerProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.rating,
    required this.totalReviews,
    required this.isVerified,
    required this.barangay,
  });
}

class Listing {
  final String id;
  final ListingType type;
  final String title;
  final String description;
  final String category;
  final double? price;
  final double? originalPrice;
  final DateTime? expiryDate;
  final DateTime postedAt;
  final double distanceKm;
  final UrgencyLevel urgency;
  final SellerProfile seller;
  final int? offerCount;
  final String? note;
  final List<String> tags;

  // Add these missing fields
  final List<String>? images;
  final bool isFree;
  final bool allowDelivery;
  final String? dealLocation;
  final bool isSaved;

  const Listing({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.price,
    this.originalPrice,
    this.expiryDate,
    required this.postedAt,
    required this.distanceKm,
    required this.urgency,
    required this.seller,
    this.offerCount,
    this.note,
    required this.tags,
    this.images,
    this.isFree = false,
    this.allowDelivery = false,
    this.dealLocation,
    this.isSaved = false,
  });

  Listing copyWith({bool? isSaved}) {
    return Listing(
      id: id,
      type: type,
      title: title,
      description: description,
      category: category,
      price: price,
      originalPrice: originalPrice,
      expiryDate: expiryDate,
      postedAt: postedAt,
      distanceKm: distanceKm,
      urgency: urgency,
      seller: seller,
      offerCount: offerCount,
      note: note,
      tags: tags,
      images: images,
      isFree: isFree,
      allowDelivery: allowDelivery,
      dealLocation: dealLocation,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  String get urgencyLabel {
    switch (urgency) {
      case UrgencyLevel.critical:
        return 'Expires tomorrow';
      case UrgencyLevel.soon:
        return 'Expires in 2 days';
      case UrgencyLevel.safe:
        return '3+ days left';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(postedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  double get discountPercent {
    if (price == null || originalPrice == null) return 0;
    return ((originalPrice! - price!) / originalPrice! * 100);
  }
}
