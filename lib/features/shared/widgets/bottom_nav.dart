import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final bool isAdmin;
  final String currentTab;
  final Function(String) onTabSelected;

  const AppBottomNav({
    super.key,
    required this.isAdmin,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = isAdmin ? _adminItems : _parentItems;
    int currentIndex = items.indexWhere((i) => i.tab == currentTab);
    if (currentIndex < 0) currentIndex = 0;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => onTabSelected(items[i].tab),
      items: items.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        activeIcon: Icon(item.activeIcon),
        label: item.label,
      )).toList(),
    );
  }

  static const _adminItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 'dashboard'),
    _NavItem(Icons.people_outlined, Icons.people, 'Students', 'students'),
    _NavItem(Icons.payment_outlined, Icons.payment, 'Payments', 'payments'),
    _NavItem(Icons.notifications_outlined, Icons.notifications, 'Alerts', 'notifications'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings', 'settings'),
  ];

  static const _parentItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Home', 'dashboard'),
    _NavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Fees', 'fees'),
    _NavItem(Icons.gps_fixed_outlined, Icons.gps_fixed, 'Track', 'parent_tracking'),
    _NavItem(Icons.notifications_outlined, Icons.notifications, 'Alerts', 'parent_notifications'),
    _NavItem(Icons.settings_outlined, Icons.settings, 'Settings', 'parent_settings'),
  ];
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tab;

  const _NavItem(this.icon, this.activeIcon, this.label, this.tab);
}
