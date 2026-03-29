import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 2; // Start on Marketplace
  String? _pantryHighlightItemId;
  bool _shouldRefetchMarketplace = false;

  int get currentIndex => _currentIndex;
  String? get pantryHighlightItemId => _pantryHighlightItemId;
  bool get shouldRefetchMarketplace => _shouldRefetchMarketplace;

  void navigateTo(int index) {
    if (_currentIndex == index) return;
    
    // Mark marketplace for refetch when navigating away and back
    if (_currentIndex == 2) {
      _shouldRefetchMarketplace = true;
    }
    
    _currentIndex = index;
    notifyListeners();
  }

  void navigateToPantryItem(String itemId) {
    _pantryHighlightItemId = itemId;
    _currentIndex = 0;
    notifyListeners();
  }

  void clearPantryHighlight() {
    _pantryHighlightItemId = null;
    notifyListeners();
  }

  void clearMarketplaceRefetchFlag() {
    _shouldRefetchMarketplace = false;
  }
}
