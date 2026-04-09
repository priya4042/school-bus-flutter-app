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
    if (auth.user != null) {
      context.read<NotificationProvider>().fetchNotifications(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final prov = context.watch<NotificationProvider>();
    final notifications = _showUnreadOnly ? prov.unread : prov.notifications;

    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          FilterChip(
            label: Text('All (${prov.notifications.length})'),
            selected: !_showUnreadOnly,
            onSelected: (_) => setState(() => _showUnreadOnly = false),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('Unread (${prov.unreadCount})'),
            selected: _showUnreadOnly,
            onSelected: (_) => setState(() => _showUnreadOnly = true),
          ),
          const Spacer(),
          if (prov.unreadCount > 0)
            TextButton(
              onPressed: () {
                if (auth.user != null) prov.markAllAsRead(auth.user!.id);
              },
              child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
            ),
        ]),
      ),

      // List
      Expanded(
        child: prov.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? const EmptyState(icon: Icons.notifications_none, title: 'All caught up!',
                    subtitle: 'No notifications to show')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      IconData icon;
                      Color color;
                      switch (n.type) {
                        case 'FEE_DUE': icon = Icons.payment; color = AppColors.warning; break;
                        case 'PAYMENT_SUCCESS': icon = Icons.check_circle; color = AppColors.success; break;
                        case 'BUS_UPDATE': icon = Icons.directions_bus; color = AppColors.info; break;
                        case 'WARNING': icon = Icons.warning; color = AppColors.error; break;
                        default: icon = Icons.info; color = AppColors.info;
                      }

                      return Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: AppColors.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => prov.deleteNotification(n.id),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          color: n.isRead ? null : AppColors.info.withOpacity(0.04),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            title: Text(n.title,
                                style: TextStyle(
                                    fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                    fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(Formatters.relativeTime(n.createdAt),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: !n.isRead
                                ? Container(width: 8, height: 8,
                                    decoration: const BoxDecoration(
                                        color: AppColors.info, shape: BoxShape.circle))
                                : null,
                            onTap: () {
                              if (!n.isRead) prov.markAsRead(n.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }
}
