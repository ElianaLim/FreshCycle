import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../data/sample_data.dart';
import '../data/db.dart';

class ListingTransactionState {
  final String listingId;
  final String? buyerId;
  final bool buyerConfirmed;
  final bool completed;
  final double feePercent;
  final double? agreedPrice;

  const ListingTransactionState({
    required this.listingId,
    required this.buyerId,
    required this.buyerConfirmed,
    required this.completed,
    required this.feePercent,
    required this.agreedPrice,
  });

  factory ListingTransactionState.fromMap(Map<String, dynamic> map) {
    return ListingTransactionState(
      listingId: map['listing_id'] as String,
      buyerId: map['buyer_id'] as String?,
      buyerConfirmed: map['buyer_confirmed'] as bool? ?? false,
      completed: map['completed'] as bool? ?? false,
      feePercent: (map['fee_percent'] as num?)?.toDouble() ?? 0.02,
      agreedPrice: (map['agreed_price'] as num?)?.toDouble(),
    );
  }
}

class ListingProvider extends ChangeNotifier {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  bool _isUuid(String? value) {
    if (value == null) return false;
    return _uuidPattern.hasMatch(value);
  }

  List<Listing> _listings = List.from(sampleListings);
  List<Listing> _requests = List.from(sampleRequests);
  final Set<String> _completedListingIds = <String>{};
  final Map<String, String> _completedListingSellers = <String, String>{};
  final Map<String, ListingTransactionState> _transactionStates =
      <String, ListingTransactionState>{};
  bool _isLoading = false;

  List<Listing> get listings => _listings;
  List<Listing> get requests => _requests;
  List<Listing> get savedListings => _listings.where((l) => l.isSaved).toList();
  List<Listing> get savedRequests => _requests.where((r) => r.isSaved).toList();
  bool get isLoading => _isLoading;

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

      _listings = [...sampleListings, ...newListings];
      _requests = [...sampleRequests, ...newRequests];
    } catch (e) {
      print('Error loading listings from DB: $e');
      _listings = List.from(sampleListings);
      _requests = List.from(sampleRequests);
    }

    _isLoading = false;
    notifyListeners();
  }

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

      // Compute urgency from expiry date
      DateTime? expiryDate;
      if (row['expiry_date'] != null) {
        expiryDate = DateTime.tryParse(row['expiry_date'] as String);
      }

      UrgencyLevel? computedUrgency;
      if (expiryDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expiry = DateTime(
          expiryDate.year,
          expiryDate.month,
          expiryDate.day,
        );
        final daysLeft = expiry.difference(today).inDays;

        if (daysLeft <= 1) {
          computedUrgency = UrgencyLevel.critical;
        } else if (daysLeft <= 2) {
          computedUrgency = UrgencyLevel.soon;
        } else {
          computedUrgency = UrgencyLevel.safe;
        }
      }

      return Listing(
        id: row['id'] as String,
        sellerId: sellerId,
        type: typeStr == 'requesting'
            ? ListingType.requesting
            : ListingType.selling,
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        category: row['category'] as String? ?? 'Uncategorized',
        price: (row['price'] as num?)?.toDouble(),
        originalPrice: (row['original_price'] as num?)?.toDouble(),
        expiryDate: expiryDate,
        postedAt: row['posted_at'] != null
            ? DateTime.tryParse(row['posted_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        urgency: computedUrgency,
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

  ListingTransactionState? transactionStateForListing(String listingId) {
    return _transactionStates[listingId];
  }

  bool isBuyerConfirmedForListing(String listingId, {String? buyerId}) {
    final tx = _transactionStates[listingId];
    if (tx == null || !tx.buyerConfirmed) return false;
    if (buyerId == null) return true;
    return tx.buyerId == buyerId;
  }

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

  Future<void> refreshTransactionState(String listingId) async {
    if (!_isUuid(listingId)) {
      return;
    }

    try {
      final tx = await DB.getListingTransaction(listingId);
      if (tx == null) return;
      _transactionStates[listingId] = ListingTransactionState.fromMap(tx);
      notifyListeners();
    } catch (e) {
      print('Failed to refresh transaction state: $e');
    }
  }

  Future<bool> confirmBuyerPurchaseIntent({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required double? agreedPrice,
    double feePercent = 0.02,
  }) async {
    final useDb = _isUuid(listingId) && _isUuid(buyerId) && _isUuid(sellerId);

    if (!useDb) {
      _transactionStates[listingId] = ListingTransactionState(
        listingId: listingId,
        buyerId: buyerId,
        buyerConfirmed: true,
        completed: false,
        feePercent: feePercent,
        agreedPrice: agreedPrice,
      );
      notifyListeners();
      return true;
    }

    try {
      final tx = await DB.upsertListingTransaction(
        listingId: listingId,
        buyerId: buyerId,
        sellerId: sellerId,
        buyerConfirmed: true,
        completed: false,
        feePercent: feePercent,
        agreedPrice: agreedPrice,
      );

      if (tx != null) {
        _transactionStates[listingId] = ListingTransactionState.fromMap(tx);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Failed to confirm buyer purchase intent in DB: $e');
    }

    return false;
  }

  Future<bool> completeListingTransaction(
    String listingId, {
    required String sellerId,
  }) async {
    if (_completedListingIds.contains(listingId)) return false;

    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index == -1) return false;

    final listing = _listings[index];
    final tx = _transactionStates[listingId];
    if (tx == null || !tx.buyerConfirmed || tx.buyerId == null) {
      return false;
    }

    if (listing.seller.id != sellerId) return false;

    final useDb =
        _isUuid(listingId) && _isUuid(sellerId) && _isUuid(tx.buyerId);

    if (useDb) {
      try {
        final didPersist = await DB.completeListingTransaction(
          listingId: listingId,
          sellerId: sellerId,
          buyerId: tx.buyerId!,
        );
        if (!didPersist) return false;
      } catch (e) {
        print('Failed to complete transaction in DB: $e');
        return false;
      }
    }

    _completedListingSellers[listingId] = listing.seller.id;
    _completedListingIds.add(listingId);
    _transactionStates[listingId] = ListingTransactionState(
      listingId: listingId,
      buyerId: tx.buyerId,
      buyerConfirmed: true,
      completed: true,
      feePercent: tx.feePercent,
      agreedPrice: tx.agreedPrice,
    );

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
