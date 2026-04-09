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
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user.isSuperAdmin
                          ? 'Super Admin'
                          : user.isAdmin
                              ? 'Admin'
                              : 'Parent',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Nav Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: user.isAdmin
                    ? _buildAdminItems()
                    : _buildParentItems(),
              ),
            ),

            // Logout
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error,
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onLogout();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAdminItems() {
    return [
      _navItem(Icons.dashboard_outlined, 'Dashboard', 'dashboard'),
      _navItem(Icons.people_outlined, 'Students', 'students'),
      _navItem(Icons.directions_bus_outlined, 'Buses', 'buses'),
      _navItem(Icons.route_outlined, 'Routes', 'routes'),
      _navItem(Icons.fact_check_outlined, 'Attendance', 'attendance'),
      _navItem(Icons.payment_outlined, 'Payments', 'payments'),
      _navItem(Icons.bar_chart_outlined, 'Reports', 'reports'),
      _navItem(Icons.notifications_outlined, 'Notifications', 'notifications'),
      _navItem(Icons.gps_fixed_outlined, 'Live Tracking', 'tracking'),
      if (user.isSuperAdmin)
        _navItem(Icons.admin_panel_settings_outlined, 'Admin Management',
            'management'),
      _navItem(Icons.settings_outlined, 'Settings', 'settings'),
    ];
  }

  List<Widget> _buildParentItems() {
    return [
      _navItem(Icons.dashboard_outlined, 'Dashboard', 'dashboard'),
      _navItem(Icons.person_outlined, 'Student Profile', 'student_profile'),
      _navItem(Icons.receipt_long_outlined, 'Fees', 'fees'),
      _navItem(Icons.receipt_outlined, 'Receipts', 'receipts'),
      _navItem(Icons.fact_check_outlined, 'Attendance', 'attendance_history'),
      _navItem(Icons.route_outlined, 'Routes', 'parent_routes'),
      _navItem(Icons.gps_fixed_outlined, 'Live Tracking', 'parent_tracking'),
      _navItem(Icons.videocam_outlined, 'Bus Camera', 'bus_camera'),
      _navItem(Icons.notifications_outlined, 'Notifications',
          'parent_notifications'),
      _navItem(Icons.support_agent_outlined, 'Support', 'support'),
      _navItem(Icons.settings_outlined, 'Settings', 'parent_settings'),
    ];
  }

  Widget _navItem(IconData icon, String label, String tab) {
    final isSelected = currentTab == tab;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary),
      title: Text(label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          )),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () => onTabSelected(tab),
    );
  }
}
