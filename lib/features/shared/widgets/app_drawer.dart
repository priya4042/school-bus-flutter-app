import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';

/// Sidebar matching React app exactly
/// - bg-slate-950 dark theme
/// - Submenus for Parent: Payments (Fees, Receipts), Profile (Edit, Password, Language), Support (Ticket, FAQ)
/// - Conditional items: Live Tracking + Bus Camera (only if preferences enabled)
/// - Bus Admins menu only for Super Admin
class AppDrawer extends StatefulWidget {
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
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final Map<String, bool> _expanded = {};

  bool _isExpanded(String key) {
    if (_isInGroup(widget.currentTab, key)) return true;
    return _expanded[key] ?? false;
  }

  bool _isInGroup(String tab, String group) {
    const groupMap = {
      'payments_parent': ['fees', 'receipts'],
      'profile_parent': ['parent_settings', 'parent_settings_password', 'parent_settings_lang'],
      'support_parent': ['support', 'support_faq'],
    };
    return groupMap[group]?.contains(tab) ?? false;
  }

  void _toggle(String key) => setState(() => _expanded[key] = !_isExpanded(key));

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.slate950,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(children: [
          // ===== HEADER =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16)],
                ),
                child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BUSWAY PRO',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13,
                      fontWeight: FontWeight.w900, letterSpacing: -0.3, color: Colors.white)),
                Text('ENTERPRISE FLEET',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 7,
                      fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.primary.withOpacity(0.9))),
              ])),
            ]),
          ),

          const SizedBox(height: 8),
          // Subtle divider under header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),
          const SizedBox(height: 12),

          // ===== NAV ITEMS =====
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: widget.user.isAdmin ? _adminItems() : _parentItems(),
            ),
          ),

          // ===== LOGOUT =====
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(context: context, builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('SIGN OUT', style: TextStyle(fontFamily: 'PlusJakartaSans',
                      fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                    content: const Text('Are you sure you want to sign out?',
                      style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx),
                        child: const Text('CANCEL', style: TextStyle(fontFamily: 'PlusJakartaSans',
                          fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.slate500))),
                      ElevatedButton(
                        onPressed: () { Navigator.pop(ctx); widget.onLogout(); },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                        child: const Text('SIGN OUT', style: TextStyle(fontFamily: 'PlusJakartaSans',
                          fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ],
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: AppColors.red500.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.logout_rounded, color: AppColors.red400, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Text('SIGN OUT', style: TextStyle(fontFamily: 'PlusJakartaSans',
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

  // ===== ADMIN MENU (matches React Sidebar.tsx Lines 32-43) =====
  List<Widget> _adminItems() => [
    _navItem(Icons.pie_chart_rounded, 'DASHBOARD', 'dashboard'),
    _navItem(Icons.school_rounded, 'STUDENTS', 'students'),
    _navItem(Icons.fact_check_rounded, 'ATTENDANCE', 'attendance'),
    _navItem(Icons.directions_bus_rounded, 'BUSES', 'buses'),
    _navItem(Icons.gps_fixed_rounded, 'LIVE TRACKING', 'tracking'),
    _navItem(Icons.credit_card_rounded, 'PAYMENTS', 'payments'),
    _navItem(Icons.bar_chart_rounded, 'REPORTS', 'reports'),
    _navItem(Icons.campaign_rounded, 'NOTIFICATIONS', 'notifications'),
    if (widget.user.isSuperAdmin)
      _navItem(Icons.admin_panel_settings_rounded, 'BUS ADMINS', 'management'),
    _navItem(Icons.settings_rounded, 'SETTINGS', 'settings'),
    _navItem(Icons.headset_mic_rounded, 'SUPPORT', 'support'),
  ];

  // ===== PARENT MENU (matches React Sidebar.tsx Lines 45-75) =====
  List<Widget> _parentItems() {
    final hasTracking = widget.user.preferences.tracking == true;
    final hasCamera = widget.user.preferences.camera == true;

    return [
      _navItem(Icons.home_rounded, 'DASHBOARD', 'dashboard'),
      _navItem(Icons.school_rounded, 'STUDENT PROFILE', 'student_profile'),
      _navItem(Icons.fact_check_rounded, 'ATTENDANCE HISTORY', 'attendance_history'),
      _navItem(Icons.route_rounded, 'ROUTES', 'parent_routes'),
      if (hasTracking) _navItem(Icons.gps_fixed_rounded, 'LIVE TRACKING', 'parent_tracking'),
      if (hasCamera) _navItem(Icons.videocam_rounded, 'BUS CAMERA', 'bus_camera'),

      // PAYMENTS submenu
      _submenu(Icons.credit_card_rounded, 'PAYMENTS', 'payments_parent', [
        _subItem(Icons.receipt_long_rounded, 'FEES', 'fees'),
        _subItem(Icons.receipt_rounded, 'RECEIPTS', 'receipts'),
      ]),

      _navItem(Icons.notifications_rounded, 'NOTIFICATIONS', 'parent_notifications'),

      // PROFILE submenu
      _submenu(Icons.person_rounded, 'PROFILE', 'profile_parent', [
        _subItem(Icons.edit_rounded, 'EDIT PROFILE', 'parent_settings'),
        _subItem(Icons.lock_rounded, 'PASSWORD RESET', 'parent_settings_password'),
        _subItem(Icons.language_rounded, 'LANGUAGE', 'parent_settings_lang'),
      ]),

      // SUPPORT submenu
      _submenu(Icons.headset_mic_rounded, 'SUPPORT', 'support_parent', [
        _subItem(Icons.confirmation_number_rounded, 'SUBMIT TICKET', 'support'),
        _subItem(Icons.help_rounded, 'FAQ', 'support_faq'),
      ]),
    ];
  }

  Widget _navItem(IconData icon, String label, String tab) {
    final isActive = widget.currentTab == tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => widget.onTabSelected(tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))] : null,
            ),
            child: Row(children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.slate500),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans',
                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                color: isActive ? Colors.white : AppColors.slate500))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _submenu(IconData icon, String label, String groupKey, List<Widget> children) {
    final hasActiveChild = _isInGroup(widget.currentTab, groupKey);
    final expanded = _isExpanded(groupKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _toggle(groupKey),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasActiveChild ? Colors.white.withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(icon, size: 16, color: hasActiveChild ? Colors.white : AppColors.slate500),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans',
                  fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                  color: hasActiveChild ? Colors.white : AppColors.slate500))),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.chevron_right_rounded, size: 16,
                    color: hasActiveChild ? Colors.white : AppColors.slate500),
                ),
              ]),
            ),
          ),
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.only(left: 22, top: 4, bottom: 4),
            padding: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.white12, width: 1))),
            child: Column(children: children),
          ),
      ]),
    );
  }

  Widget _subItem(IconData icon, String label, String tab) {
    final isActive = widget.currentTab == tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onTabSelected(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(icon, size: 13, color: isActive ? AppColors.primary : AppColors.slate500),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans',
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5,
                color: isActive ? AppColors.primary : AppColors.slate500))),
            ]),
          ),
        ),
      ),
    );
  }
}
