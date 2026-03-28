import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../data/sample_data.dart';

class ListingProvider extends ChangeNotifier {
  final List<Listing> _listings = List.from(sampleListings);
  final List<Listing> _requests = List.from(sampleRequests);
  final Set<String> _completedListingIds = <String>{};
  final Map<String, String> _completedListingSellers = <String, String>{};

  List<Listing> get listings => _listings;
  List<Listing> get requests => _requests;
  List<Listing> get savedListings => _listings.where((l) => l.isSaved).toList();
  List<Listing> get savedRequests => _requests.where((r) => r.isSaved).toList();

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
