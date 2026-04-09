import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String _currentTab = 'dashboard';

  int get currentIndex => _currentIndex;
  String get currentTab => _currentTab;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setTab(String tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    _currentTab = 'dashboard';
    notifyListeners();
  }
}
