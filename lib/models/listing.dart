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
  final String? sellerId;
  final ListingType type;
  final String title;
  final String description;
  final String category;
  final double? price;
  final double? originalPrice;
  final DateTime? expiryDate;
  final DateTime postedAt;
  final UrgencyLevel urgency;
  final SellerProfile seller;
  final int? offerCount;
  final String? note;
  final List<String> tags;

  // App-specific runtime fields (not persisted to DB)
  final double distanceKm;
  final List<String>? images;
  final bool isFree;
  final bool allowDelivery;
  final String? dealLocation;
  final bool isSaved;

  const Listing({
    required this.id,
    this.sellerId,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.price,
    this.originalPrice,
    this.expiryDate,
    required this.postedAt,
    required this.urgency,
    required this.seller,
    this.offerCount,
    this.note,
    required this.tags,
    this.distanceKm = 0.0,
    this.images,
    this.isFree = false,
    this.allowDelivery = false,
    this.dealLocation,
    this.isSaved = false,
  });

  /// Creates a Listing from Supabase database row
  factory Listing.fromDb({
    required String id,
    required String? sellerId,
    required ListingType type,
    required String title,
    String? description,
    required String category,
    double? price,
    double? originalPrice,
    DateTime? expiryDate,
    required DateTime postedAt,
    required UrgencyLevel urgency,
    int? offerCount,
    String? note,
    List<String>? tags,
    required SellerProfile seller,
    double distanceKm = 0.0,
    List<String>? images,
    bool isFree = false,
    bool allowDelivery = false,
    String? dealLocation,
    bool isSaved = false,
  }) {
    return Listing(
      id: id,
      sellerId: sellerId,
      type: type,
      title: title,
      description: description ?? '',
      category: category,
      price: price,
      originalPrice: originalPrice,
      expiryDate: expiryDate,
      postedAt: postedAt,
      urgency: urgency,
      seller: seller,
      offerCount: offerCount,
      note: note,
      tags: tags ?? [],
      distanceKm: distanceKm,
      images: images,
      isFree: isFree,
      allowDelivery: allowDelivery,
      dealLocation: dealLocation,
      isSaved: isSaved,
    );
  }

  Listing copyWith({
    bool? isSaved,
    String? sellerId,
    ListingType? type,
    String? title,
    String? description,
    String? category,
    double? price,
    double? originalPrice,
    DateTime? expiryDate,
    DateTime? postedAt,
    UrgencyLevel? urgency,
    int? offerCount,
    String? note,
    List<String>? tags,
    SellerProfile? seller,
    double? distanceKm,
    List<String>? images,
    bool? isFree,
    bool? allowDelivery,
    String? dealLocation,
  }) {
    return Listing(
      id: id,
      sellerId: sellerId ?? this.sellerId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      expiryDate: expiryDate ?? this.expiryDate,
      postedAt: postedAt ?? this.postedAt,
      urgency: urgency ?? this.urgency,
      seller: seller ?? this.seller,
      offerCount: offerCount ?? this.offerCount,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      distanceKm: distanceKm ?? this.distanceKm,
      images: images ?? this.images,
      isFree: isFree ?? this.isFree,
      allowDelivery: allowDelivery ?? this.allowDelivery,
      dealLocation: dealLocation ?? this.dealLocation,
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
