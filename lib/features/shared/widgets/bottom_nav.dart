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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate100)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isActive = currentTab == item.tab;
              return GestureDetector(
                onTap: () => onTabSelected(item.tab),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 64,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Active indicator dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isActive ? 20 : 0,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    AnimatedScale(
                      scale: isActive ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(item.icon, size: 22,
                          color: isActive ? AppColors.primary : AppColors.slate400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: isActive ? AppColors.primary : AppColors.slate400,
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static const _adminItems = [
    _NavItem(Icons.pie_chart_rounded, 'HOME', 'dashboard'),
    _NavItem(Icons.credit_card_rounded, 'PAYMENTS', 'payments'),
    _NavItem(Icons.campaign_rounded, 'ALERTS', 'notifications'),
    _NavItem(Icons.school_rounded, 'STUDENTS', 'students'),
    _NavItem(Icons.settings_rounded, 'SETTINGS', 'settings'),
  ];

  static const _parentItems = [
    _NavItem(Icons.home_rounded, 'HOME', 'dashboard'),
    _NavItem(Icons.credit_card_rounded, 'FEES', 'fees'),
    _NavItem(Icons.notifications_rounded, 'ALERTS', 'parent_notifications'),
    _NavItem(Icons.person_rounded, 'PROFILE', 'student_profile'),
    _NavItem(Icons.settings_rounded, 'SETTINGS', 'parent_settings'),
  ];
}

class _NavItem {
  final IconData icon;
  final String label;
  final String tab;
  const _NavItem(this.icon, this.label, this.tab);
}
