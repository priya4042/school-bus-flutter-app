import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'app_drawer.dart';
import 'bottom_nav.dart';

// Admin pages
import '../../admin/dashboard/admin_dashboard_screen.dart';
import '../../admin/students/students_screen.dart';
import '../../admin/buses/buses_screen.dart';
import '../../admin/routes/routes_screen.dart';
import '../../admin/attendance/attendance_screen.dart';
import '../../admin/payments/admin_payments_screen.dart';
import '../../admin/notifications/admin_notifications_screen.dart';
import '../../admin/management/admin_management_screen.dart';
import '../../admin/tracking/admin_tracking_screen.dart';
import '../../admin/settings/admin_settings_screen.dart';
import '../../admin/reports/reports_screen.dart';

// Parent pages
import '../../parent/dashboard/parent_dashboard_screen.dart';
import '../../parent/profile/student_profile_screen.dart';
import '../../parent/fees/fee_history_screen.dart';
import '../../parent/payments/parent_receipts_screen.dart';
import '../../parent/attendance/attendance_history_screen.dart';
import '../../parent/routes/parent_routes_screen.dart';
import '../../parent/tracking/parent_tracking_screen.dart';
import '../../parent/camera/bus_camera_screen.dart';
import '../../parent/notifications/parent_notifications_screen.dart';
import '../../parent/support/support_screen.dart';
import '../../parent/settings/parent_settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      if (auth.user != null) {
        context.read<NotificationProvider>().subscribe(auth.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final nav = context.watch<NavigationProvider>();
    final notifications = context.watch<NotificationProvider>();

    if (auth.user == null) return const SizedBox.shrink();
    final isAdmin = auth.user!.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      // Topbar: bg-white/80 backdrop-blur-md sticky border-b border-slate-100
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.slate800),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(children: [
          // Status dot: w-2 h-2 bg-success rounded-full animate-pulse
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            isAdmin ? 'GLOBAL FLEET' : 'MAIN PORTAL',
            style: TextStyle(fontFamily: 'PlusJakartaSans', 
              fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: 2, color: AppColors.slate400,
            ),
          ),
          const SizedBox(width: 6),
          Text('ONLINE', style: TextStyle(fontFamily: 'PlusJakartaSans', 
            fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.success)),
        ]),
        actions: [
          // Notification bell
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.slate400),
              onPressed: () => nav.setTab(isAdmin ? 'notifications' : 'parent_notifications'),
            ),
            if (notifications.unreadCount > 0)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.red500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(child: Text(
                    notifications.unreadCount > 9 ? '9+' : '${notifications.unreadCount}',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', 
                      fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                  )),
                ),
              ),
          ]),
          // Avatar + Name + Role with user menu popup
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.slate100),
              ),
              elevation: 12,
              color: Colors.white,
              padding: EdgeInsets.zero,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                // Name + Role text (right-aligned)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      auth.user!.fullName.split(' ').first,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.slate800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAdmin ? 'ADMIN' : 'PARENT',
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppColors.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Avatar circle with image or initial
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.slate200, width: 2),
                  ),
                  child: ClipOval(
                    child: auth.user!.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty
                        ? Image.network(
                            auth.user!.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _initialAvatar(auth.user!.fullName),
                          )
                        : _initialAvatar(auth.user!.fullName),
                  ),
                ),
              ]),
              itemBuilder: (ctx) => [
                // Header with name + role
                PopupMenuItem<String>(
                  enabled: false,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.slate100)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user!.fullName,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.user!.email,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isAdmin)
                  _menuItem('edit_profile', Icons.edit_rounded, 'EDIT PROFILE'),
                _menuItem(isAdmin ? 'settings' : 'parent_settings', Icons.settings_rounded, 'SETTINGS'),
                if (!isAdmin)
                  _menuItem('parent_settings_lang', Icons.language_rounded, 'LANGUAGE'),
                const PopupMenuDivider(),
                _menuItem('logout', Icons.logout_rounded, 'LOGOUT', isLogout: true),
              ],
              onSelected: (value) async {
                if (value == 'logout') {
                  await auth.logout();
                  nav.reset();
                } else if (value == 'edit_profile') {
                  nav.setTab('parent_settings');
                } else {
                  nav.setTab(value);
                }
              },
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        user: auth.user!,
        currentTab: nav.currentTab,
        onTabSelected: (tab) { nav.setTab(tab); Navigator.pop(context); },
        onLogout: () async { await auth.logout(); nav.reset(); },
      ),
      body: _buildBody(nav.currentTab, isAdmin),
      bottomNavigationBar: AppBottomNav(
        isAdmin: isAdmin,
        currentTab: nav.currentTab,
        onTabSelected: nav.setTab,
      ),
    );
  }

  Widget _initialAvatar(String fullName) {
    return Container(
      color: AppColors.slate900,
      alignment: Alignment.center,
      child: Text(
        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {bool isLogout = false}) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(children: [
        Icon(icon, size: 16, color: isLogout ? AppColors.danger : AppColors.slate500),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: isLogout ? AppColors.danger : AppColors.slate700,
          ),
        ),
      ]),
    );
  }

  Widget _buildBody(String tab, bool isAdmin) {
    if (isAdmin) {
      switch (tab) {
        case 'dashboard': return const AdminDashboardScreen();
        case 'students': return const StudentsScreen();
        case 'buses': return const BusesScreen();
        case 'routes': return const RoutesScreen();
        case 'attendance': return const AttendanceScreen();
        case 'payments': return const AdminPaymentsScreen();
        case 'notifications': return const AdminNotificationsScreen();
        case 'management': return const AdminManagementScreen();
        case 'tracking': return const AdminTrackingScreen();
        case 'settings': return const AdminSettingsScreen();
        case 'reports': return const ReportsScreen();
        default: return const AdminDashboardScreen();
      }
    } else {
      switch (tab) {
        case 'dashboard': return const ParentDashboardScreen();
        case 'student_profile': return const StudentProfileScreen();
        case 'fees': return const FeeHistoryScreen();
        case 'receipts': return const ParentReceiptsScreen();
        case 'attendance_history': return const AttendanceHistoryScreen();
        case 'parent_routes': return const ParentRoutesScreen();
        case 'parent_tracking': return const ParentTrackingScreen();
        case 'bus_camera': return const BusCameraScreen();
        case 'parent_notifications': return const ParentNotificationsScreen();
        case 'support':
          return const SupportScreen(initialTab: 0);
        case 'support_faq':
          return const SupportScreen(initialTab: 1);
        case 'parent_settings':
          return const ParentSettingsScreen(initialTab: 0);
        case 'parent_settings_password':
          return const ParentSettingsScreen(initialTab: 1);
        case 'parent_settings_lang':
          return const ParentSettingsScreen(initialTab: 2);
        default: return const ParentDashboardScreen();
      }
    }
  }
}
