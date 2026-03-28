import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../data/sample_data.dart';

class ListingProvider extends ChangeNotifier {
  // Initialize with your sample data
  final List<Listing> _listings = List.from(sampleListings);

  List<Listing> get listings => _listings;

  void addListing(Listing newListing) {
    _listings.insert(0, newListing);
    notifyListeners();
  }

  void toggleSave(String id) {
    final index = _listings.indexWhere((l) => l.id == id);
    if (index != -1) {
      _listings[index] = _listings[index].copyWith(
        isSaved: !_listings[index].isSaved,
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
}
