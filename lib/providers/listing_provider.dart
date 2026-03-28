import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../data/sample_data.dart';
import '../data/db.dart';

class ListingProvider extends ChangeNotifier {
  List<Listing> _listings = List.from(sampleListings);
  List<Listing> _requests = List.from(sampleRequests);
  final Set<String> _completedListingIds = <String>{};
  final Map<String, String> _completedListingSellers = <String, String>{};
  bool _isLoading = false;

  List<Listing> get listings => _listings;
  List<Listing> get requests => _requests;
  List<Listing> get savedListings => _listings.where((l) => l.isSaved).toList();
  List<Listing> get savedRequests => _requests.where((r) => r.isSaved).toList();
  bool get isLoading => _isLoading;

  /// Load listings from database and append to hardcoded listings
  Future<void> loadListingsFromDb() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch listings from database
      final dbListings = await DB.getListings();
      final dbRequests = await DB.getRequests();

      // Convert database rows to Listing objects
      final List<Listing> newListings = [];
      for (final row in dbListings) {
        final listing = await _mapDbToListing(row);
        if (listing != null) newListings.add(listing);
      }

      final List<Listing> newRequests = [];
      for (final row in dbRequests) {
        final request = await _mapDbToListing(row);
        if (request != null) newRequests.add(request);
      }

      // Combine with sample data (sample data first, then DB data)
      _listings = [...sampleListings, ...newListings];
      _requests = [...sampleRequests, ...newRequests];
    } catch (e) {
      print('Error loading listings from DB: $e');
      // Keep sample data on error
      _listings = List.from(sampleListings);
      _requests = List.from(sampleRequests);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Map database row to Listing object
  Future<Listing?> _mapDbToListing(Map<String, dynamic> row) async {
    try {
      final sellerId = row['seller_id'] as String?;
      if (sellerId == null) return null;

      // Fetch seller profile
      final sellerProfile = await DB.getProfile(sellerId);
      if (sellerProfile == null) return null;

      final seller = SellerProfile(
        id: sellerProfile['id'] as String,
        name: sellerProfile['name'] as String? ?? 'Unknown',
        initials: sellerProfile['initials'] as String? ?? 'U',
        rating: (sellerProfile['rating'] as num?)?.toDouble() ?? 0.0,
        totalReviews: sellerProfile['total_reviews'] as int? ?? 0,
        isVerified: sellerProfile['is_verified'] as bool? ?? false,
        barangay: sellerProfile['barangay'] as String? ?? 'Unknown',
      );

      final typeStr = row['type'] as String? ?? 'selling';
      final urgencyStr = row['urgency'] as String? ?? 'safe';

      return Listing(
        id: row['id'] as String,
        sellerId: sellerId,
        type: typeStr == 'requesting' ? ListingType.requesting : ListingType.selling,
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        category: row['category'] as String? ?? 'Uncategorized',
        price: (row['price'] as num?)?.toDouble(),
        originalPrice: (row['original_price'] as num?)?.toDouble(),
        expiryDate: row['expiry_date'] != null
            ? DateTime.tryParse(row['expiry_date'] as String)
            : null,
        postedAt: row['posted_at'] != null
            ? DateTime.tryParse(row['posted_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        urgency: _parseUrgency(urgencyStr),
        seller: seller,
        offerCount: row['offer_count'] as int?,
        note: row['note'] as String?,
        tags: (row['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      print('Error mapping listing: $e');
      return null;
    }
  }

  UrgencyLevel _parseUrgency(String value) {
    switch (value) {
      case 'critical':
        return UrgencyLevel.critical;
      case 'soon':
        return UrgencyLevel.soon;
      default:
        return UrgencyLevel.safe;
    }
  }

  bool isListingCompleted(String listingId) =>
      _completedListingIds.contains(listingId);

  bool isSellerForListing(String listingId, String? userId) {
    if (userId == null) return false;

    final active = _listings.where((l) => l.id == listingId);
    if (active.isNotEmpty) {
      return active.first.seller.id == userId;
    }

    return _completedListingSellers[listingId] == userId;
  }

  Listing? findById(String id) {
    for (final listing in _listings) {
      if (listing.id == id) return listing;
    }
    for (final request in _requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  void addListing(Listing newListing) {
    _listings.insert(0, newListing);
    notifyListeners();
  }

  void addRequest(Listing newRequest) {
    _requests.insert(0, newRequest);
    notifyListeners();
  }

  void toggleSave(String id) {
    final listingIndex = _listings.indexWhere((l) => l.id == id);
    if (listingIndex != -1) {
      _listings[listingIndex] = _listings[listingIndex].copyWith(
        isSaved: !_listings[listingIndex].isSaved,
      );
      notifyListeners();
      return;
    }

    final requestIndex = _requests.indexWhere((r) => r.id == id);
    if (requestIndex != -1) {
      _requests[requestIndex] = _requests[requestIndex].copyWith(
        isSaved: !_requests[requestIndex].isSaved,
      );
      notifyListeners();
    }
  }

  void updateListing(Listing updatedListing) {
    final index = _listings.indexWhere((l) => l.id == updatedListing.id);
    if (index != -1) {
      _listings[index] = updatedListing;
      notifyListeners();
    }
  }

  void removeListing(String id) {
    _listings.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  bool completeListingTransaction(String listingId) {
    if (_completedListingIds.contains(listingId)) return false;

    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index == -1) return false;

    final listing = _listings[index];
    _completedListingSellers[listingId] = listing.seller.id;
    _completedListingIds.add(listingId);
    _listings.removeAt(index);
    notifyListeners();
    return true;
  }

  void updateRequest(Listing updatedRequest) {
    final index = _requests.indexWhere((r) => r.id == updatedRequest.id);
    if (index != -1) {
      _requests[index] = updatedRequest;
      notifyListeners();
    }
  }

  void removeRequest(String id) {
    _requests.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
