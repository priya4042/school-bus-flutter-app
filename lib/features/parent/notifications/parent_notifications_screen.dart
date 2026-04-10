import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});
  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AppAuthProvider>();
    if (auth.user != null) context.read<NotificationProvider>().fetchNotifications(auth.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final prov = context.watch<NotificationProvider>();
    final notifications = _showUnreadOnly ? prov.unread : prov.notifications;

    return Column(children: [
      // Filter bar
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          _filterChip('ALL (${prov.notifications.length})', !_showUnreadOnly, () => setState(() => _showUnreadOnly = false)),
          const SizedBox(width: 8),
          _filterChip('UNREAD (${prov.unreadCount})', _showUnreadOnly, () => setState(() => _showUnreadOnly = true)),
          const Spacer(),
          if (prov.unreadCount > 0)
            GestureDetector(
              onTap: () { if (auth.user != null) prov.markAllAsRead(auth.user!.id); },
              child: Text('MARK ALL READ', style: AppTheme.labelXs.copyWith(color: AppColors.primary)),
            ),
        ]),
      ),

      // List
      Expanded(
        child: prov.isLoading
            ? const MiniLoader()
            : notifications.isEmpty
                ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'ALL CAUGHT UP!', subtitle: 'No notifications')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      IconData icon; Color color;
                      switch (n.type) {
                        case 'FEE_DUE': icon = Icons.payment_rounded; color = AppColors.warning; break;
                        case 'PAYMENT_SUCCESS': icon = Icons.check_circle_rounded; color = AppColors.success; break;
                        case 'BUS_UPDATE': icon = Icons.directions_bus_rounded; color = AppColors.blue500; break;
                        case 'WARNING': icon = Icons.warning_rounded; color = AppColors.danger; break;
                        case 'SUCCESS': icon = Icons.check_circle_rounded; color = AppColors.success; break;
                        default: icon = Icons.info_rounded; color = AppColors.blue500;
                      }

                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) => prov.deleteNotification(n.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: n.isRead ? Colors.white : AppColors.blue50.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: n.isRead ? AppColors.slate100 : AppColors.primary.withOpacity(0.15)),
                          ),
                          child: InkWell(
                            onTap: () { if (!n.isRead) prov.markAsRead(n.id); },
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(n.title, style: TextStyle(fontFamily: 'PlusJakartaSans', 
                                    fontSize: 12, fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900, color: AppColors.slate800))),
                                  if (!n.isRead) Container(width: 8, height: 8,
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                ]),
                                const SizedBox(height: 4),
                                Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate500)),
                                const SizedBox(height: 6),
                                Text(Formatters.relativeTime(n.createdAt).toUpperCase(),
                                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.slate300)),
                              ])),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.slate100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', 
          fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5,
          color: selected ? Colors.white : AppColors.slate500)),
      ),
    );
  }
}
