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
      appBar: AppBar(
        title: Text(_getTitle(nav.currentTab, isAdmin)),
        actions: [
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  nav.setTab(isAdmin ? 'notifications' : 'parent_notifications');
                },
              ),
              if (notifications.unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      notifications.unreadCount > 9
                          ? '9+'
                          : '${notifications.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          // User avatar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                (auth.user!.fullName.isNotEmpty
                        ? auth.user!.fullName[0]
                        : 'U')
                    .toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        user: auth.user!,
        currentTab: nav.currentTab,
        onTabSelected: (tab) {
          nav.setTab(tab);
          Navigator.pop(context);
        },
        onLogout: () async {
          await auth.logout();
          nav.reset();
        },
      ),
      body: _buildBody(nav.currentTab, isAdmin),
      bottomNavigationBar: AppBottomNav(
        isAdmin: isAdmin,
        currentTab: nav.currentTab,
        onTabSelected: nav.setTab,
      ),
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
        case 'support': return const SupportScreen();
        case 'parent_settings': return const ParentSettingsScreen();
        default: return const ParentDashboardScreen();
      }
    }
  }

  String _getTitle(String tab, bool isAdmin) {
    final titles = {
      'dashboard': isAdmin ? 'Operations Hub' : 'Family Hub',
      'students': 'Students',
      'buses': 'Fleet Management',
      'routes': 'Routes',
      'attendance': 'Attendance',
      'payments': 'Payment Hub',
      'notifications': 'Notifications',
      'management': 'Access Control',
      'tracking': 'Live Tracking',
      'settings': 'Settings',
      'reports': 'Reports',
      'student_profile': 'Student Profile',
      'fees': 'Fee Ledger',
      'receipts': 'Receipts',
      'attendance_history': 'Attendance History',
      'parent_routes': 'Route Details',
      'parent_tracking': 'Live Tracking',
      'bus_camera': 'Bus Camera',
      'parent_notifications': 'Alert Center',
      'support': 'Support',
      'parent_settings': 'Settings',
    };
    return titles[tab] ?? 'BusWay Pro';
  }
}
