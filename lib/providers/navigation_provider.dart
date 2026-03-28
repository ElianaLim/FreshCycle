import 'package:flutter/foundation.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 2; // Start on Marketplace
  String? _pantryHighlightItemId;

  int get currentIndex => _currentIndex;
  String? get pantryHighlightItemId => _pantryHighlightItemId;

  void navigateTo(int index) {
    if (_currentIndex == index) return;
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
  }
}
