import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _msgType = 'Announcement';
  String _target = 'All Parents';
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  final _msgTypes = ['Emergency Alert', 'Announcement', 'Fee Reminder', 'Route Update'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    context.read<RouteProvider>().fetchRoutes();
  }

  Future<void> _sendBroadcast() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);

    final prov = context.read<NotificationProvider>();
    final type = _msgType == 'Emergency Alert'
        ? 'WARNING'
        : _msgType == 'Fee Reminder'
            ? 'FEE_DUE'
            : 'INFO';

    final success = await prov.broadcastToParents(
      title: _msgType,
      message: _msgCtrl.text.trim(),
      type: type,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (success) {
        _msgCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(controller: _tabCtrl, tabs: const [
          Tab(text: 'Broadcast'),
          Tab(text: 'History'),
        ]),
        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            _buildBroadcast(),
            _buildHistory(),
          ]),
        ),
      ],
    );
  }

  Widget _buildBroadcast() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Message Type', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: _msgTypes.map((t) => ChoiceChip(
          label: Text(t),
          selected: _msgType == t,
          onSelected: (_) => setState(() => _msgType = t),
          selectedColor: _msgType == 'Emergency Alert' ? AppColors.error.withOpacity(0.2) : AppColors.primary.withOpacity(0.15),
        )).toList()),
        const SizedBox(height: 16),

        const Text('Target Recipients', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _target,
          items: const [
            DropdownMenuItem(value: 'All Parents', child: Text('All Parents')),
          ],
          onChanged: (v) => setState(() => _target = v!),
          decoration: const InputDecoration(isDense: true),
        ),
        const SizedBox(height: 16),

        const Text('Message', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _msgCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Type your message here...',
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Icon(_msgType == 'Emergency Alert' ? Icons.warning : Icons.info_outline,
              size: 16, color: _msgType == 'Emergency Alert' ? AppColors.error : AppColors.info),
          const SizedBox(width: 4),
          Text(_msgType == 'Emergency Alert' ? 'Critical Priority' : 'In-app notification',
              style: TextStyle(fontSize: 12, color: _msgType == 'Emergency Alert' ? AppColors.error : AppColors.textSecondary)),
        ]),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _sendBroadcast,
            icon: _sending
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: const Text('Send Broadcast'),
          ),
        ),
      ]),
    );
  }

  Widget _buildHistory() {
    final prov = context.watch<NotificationProvider>();
    final notifications = prov.notifications;

    if (notifications.isEmpty) {
      return const Center(child: Text('No notifications yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (_, i) {
        final n = notifications[i];
        IconData icon;
        Color color;
        switch (n.type) {
          case 'WARNING': icon = Icons.warning; color = AppColors.error; break;
          case 'FEE_DUE': icon = Icons.payment; color = AppColors.warning; break;
          case 'PAYMENT_SUCCESS': icon = Icons.check_circle; color = AppColors.success; break;
          case 'BUS_UPDATE': icon = Icons.directions_bus; color = AppColors.info; break;
          default: icon = Icons.info; color = AppColors.info;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text(Formatters.relativeTime(n.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }
}
