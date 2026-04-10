import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/locale_provider.dart';
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
    final locale = context.watch<LocaleProvider>();
    final t = locale.t;

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
          // Status dot
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            isAdmin ? t('global_fleet') : t('main_portal'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· ${t('online')}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.success,
            ),
          ),
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
                    style: TextStyle(fontFamily: 'Inter', 
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
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.slate900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAdmin ? 'Admin' : 'Parent',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: AppColors.primary,
                        height: 1.1,
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
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          auth.user!.email,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isAdmin)
                  _menuItem('edit_profile', Icons.edit_rounded, t('edit_profile')),
                _menuItem(isAdmin ? 'settings' : 'parent_settings', Icons.settings_rounded, t('settings')),
                // Language quick-toggle (EN/HI buttons)
                PopupMenuItem<String>(
                  enabled: false,
                  height: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('language'),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: AppColors.slate400,
                          )),
                      const SizedBox(height: 6),
                      Row(children: [
                        _langButton('en', '🇬🇧', 'EN', locale, t),
                        const SizedBox(width: 6),
                        _langButton('hi', '🇮🇳', 'हिं', locale, t),
                      ]),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                _menuItem('logout', Icons.logout_rounded, t('sign_out'), isLogout: true),
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

  Widget _langButton(String code, String flag, String label, LocaleProvider locale, String Function(String) t) {
    final isActive = locale.lang == code;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await locale.setLang(code);
          if (mounted) Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.slate50,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8)] : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isActive ? Colors.white : AppColors.slate500,
            )),
          ]),
        ),
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
          fontFamily: 'Inter',
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
      height: 46,
      child: Row(children: [
        Icon(icon, size: 18, color: isLogout ? AppColors.danger : AppColors.slate500),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
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
          return const SupportScreen(initialTab: 0, singleTab: true);
        case 'support_faq':
          return const SupportScreen(initialTab: 1, singleTab: true);
        case 'parent_settings':
          return const ParentSettingsScreen(initialTab: 0, singleTab: true);
        case 'parent_settings_password':
          return const ParentSettingsScreen(initialTab: 1, singleTab: true);
        case 'parent_settings_lang':
          return const ParentSettingsScreen(initialTab: 2, singleTab: true);
        default: return const ParentDashboardScreen();
      }
    }
  }
}
