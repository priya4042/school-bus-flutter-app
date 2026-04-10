import 'package:flutter/material.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final AppUser user;
  final String currentTab;
  final Function(String) onTabSelected;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.user,
    required this.currentTab,
    required this.onTabSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // bg-slate-950 sidebar
    return Drawer(
      backgroundColor: AppColors.slate950,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(children: [
              // Logo: bg-primary rounded-xl p-2
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)],
                ),
                child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('BUSWAY PRO', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white)),
                Text('ENTERPRISE', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.primary)),
              ]),
            ]),
          ),

          // User info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName,
                    style: TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(user.isSuperAdmin ? 'SUPER ADMIN' : user.isAdmin ? 'ADMIN' : 'PARENT',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', 
                      fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.primary)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: user.isAdmin ? _adminItems() : _parentItems(),
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Text('SIGN OUT', style: AppTheme.headingSmall),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx),
                            child: Text('CANCEL', style: AppTheme.labelSmall.copyWith(color: AppColors.slate500))),
                        ElevatedButton(
                          onPressed: () { Navigator.pop(ctx); onLogout(); },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                          child: Text('SIGN OUT', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                            fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.red500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: AppColors.red400, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text('SIGN OUT', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                      fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.slate500)),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _adminItems() => [
    _navItem(Icons.pie_chart_rounded, 'DASHBOARD', 'dashboard'),
    _navItem(Icons.school_rounded, 'STUDENTS', 'students'),
    _navItem(Icons.fact_check_rounded, 'ATTENDANCE', 'attendance'),
    _navItem(Icons.directions_bus_rounded, 'BUSES', 'buses'),
    _navItem(Icons.gps_fixed_rounded, 'LIVE TRACKING', 'tracking'),
    _navItem(Icons.credit_card_rounded, 'PAYMENTS', 'payments'),
    _navItem(Icons.bar_chart_rounded, 'REPORTS', 'reports'),
    _navItem(Icons.campaign_rounded, 'NOTIFICATIONS', 'notifications'),
    if (user.isSuperAdmin)
      _navItem(Icons.admin_panel_settings_rounded, 'BUS ADMINS', 'management'),
    _navItem(Icons.settings_rounded, 'SETTINGS', 'settings'),
    _navItem(Icons.headset_mic_rounded, 'SUPPORT', 'support_admin'),
  ];

  List<Widget> _parentItems() => [
    _navItem(Icons.home_rounded, 'DASHBOARD', 'dashboard'),
    _navItem(Icons.person_rounded, 'STUDENT PROFILE', 'student_profile'),
    _navItem(Icons.fact_check_rounded, 'ATTENDANCE', 'attendance_history'),
    _navItem(Icons.route_rounded, 'ROUTES', 'parent_routes'),
    _navItem(Icons.gps_fixed_rounded, 'LIVE TRACKING', 'parent_tracking'),
    _navItem(Icons.videocam_rounded, 'BUS CAMERA', 'bus_camera'),
    _navItem(Icons.credit_card_rounded, 'FEES', 'fees'),
    _navItem(Icons.receipt_rounded, 'RECEIPTS', 'receipts'),
    _navItem(Icons.notifications_rounded, 'NOTIFICATIONS', 'parent_notifications'),
    _navItem(Icons.settings_rounded, 'SETTINGS', 'parent_settings'),
    _navItem(Icons.headset_mic_rounded, 'SUPPORT', 'support'),
  ];

  Widget _navItem(IconData icon, String label, String tab) {
    final isActive = currentTab == tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTabSelected(tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isActive ? [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ] : null,
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: isActive ? Colors.white : AppColors.slate500),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', 
                fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                color: isActive ? Colors.white : AppColors.slate500,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
