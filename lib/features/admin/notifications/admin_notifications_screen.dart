import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _msgType = 'Announcement';
  String _target = 'All Parents';
  final _msgCtrl = TextEditingController();
  bool _sending = false;
  // Chat
  List<Map<String, dynamic>> _chatMessages = [];
  final _replyCtrls = <String, TextEditingController>{};
  StreamSubscription? _chatSub;
  // Audit logs
  List<Map<String, dynamic>> _auditLogs = [];
  String _auditSearch = '';
  bool _auditLoading = false;

  final _msgTypes = ['Emergency Alert', 'Announcement', 'Fee Reminder', 'Route Update'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    context.read<RouteProvider>().fetchRoutes();
    _loadNotifications();
    _loadChatMessages();
    _loadAuditLogs();
    _subscribeChatMessages();
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user != null) {
      await context.read<NotificationProvider>().fetchNotifications(auth.user!.id);
    }
  }

  Future<void> _loadChatMessages() async {
    try {
      final res = await Supabase.instance.client.from('notifications')
          .select('*').ilike('title', '%[CHAT]%')
          .order('created_at', ascending: false).limit(50);
      if (mounted) setState(() => _chatMessages = List<Map<String, dynamic>>.from(res));
    } catch (_) {}
  }

  void _subscribeChatMessages() {
    _chatSub = Supabase.instance.client.from('notifications')
        .stream(primaryKey: ['id']).order('created_at', ascending: false)
        .listen((data) {
      final chats = data.where((d) => (d['title'] ?? '').toString().contains('[CHAT]')).toList();
      if (mounted && chats.isNotEmpty) setState(() => _chatMessages = chats.take(50).toList());
    });
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _auditLoading = true);
    try {
      final res = await Supabase.instance.client.from('audit_logs')
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false).limit(100);
      if (mounted) setState(() { _auditLogs = List<Map<String, dynamic>>.from(res); _auditLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _auditLoading = false);
    }
  }

  Future<void> _sendBroadcast() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final prov = context.read<NotificationProvider>();
    final type = _msgType == 'Emergency Alert' ? 'WARNING' : _msgType == 'Fee Reminder' ? 'FEE_DUE' : 'INFO';
    final ok = await prov.broadcastToParents(title: _msgType, message: _msgCtrl.text.trim(), type: type);
    if (mounted) {
      setState(() => _sending = false);
      if (ok) { _msgCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BROADCAST SENT'), backgroundColor: AppColors.success)); }
    }
  }

  Future<void> _replyChat(String parentUserId, String parentName, String replyText) async {
    if (replyText.trim().isEmpty) return;
    await Supabase.instance.client.from('notifications').insert({
      'user_id': parentUserId, 'title': '[CHAT] Admin',
      'message': replyText.trim(), 'type': 'INFO', 'is_read': false,
    });
    _replyCtrls[parentUserId]?.clear();
    _loadChatMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200.withOpacity(0.5))),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.slate400,
          tabs: const [Tab(text: 'BROADCAST'), Tab(text: 'CHAT'), Tab(text: 'AUDIT LOGS')],
        ),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _buildBroadcastTab(),
        _buildChatTab(),
        _buildAuditLogsTab(),
      ])),
    ]);
  }

  // ===== BROADCAST TAB =====
  Widget _buildBroadcastTab() {
    final prov = context.watch<NotificationProvider>();
    final routes = context.watch<RouteProvider>().routes;
    final recentBroadcasts = prov.notifications.where((n) => n.type == 'INFO' || n.type == 'WARNING' || n.type == 'FEE_DUE').take(5).toList();
    // Payment confirmations
    final paymentNotifs = prov.notifications.where((n) => n.type == 'PAYMENT_SUCCESS').take(10).toList();

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Broadcast form
      Container(padding: const EdgeInsets.all(20), decoration: AppTheme.cardLargeDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BROADCAST TO PARENTS', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
          const SizedBox(height: 16),
          Text('MESSAGE TYPE', style: AppTheme.labelSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _msgTypes.map((t) {
            final sel = _msgType == t;
            return GestureDetector(
              onTap: () => setState(() => _msgType = t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? (t == 'Emergency Alert' ? AppColors.danger.withOpacity(0.15) : AppColors.primary.withOpacity(0.15)) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(10)),
                child: Text(t.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1,
                    color: sel ? (t == 'Emergency Alert' ? AppColors.danger : AppColors.primary) : AppColors.slate500)),
              ),
            );
          }).toList()),
          const SizedBox(height: 16),
          Text('TARGET RECIPIENTS', style: AppTheme.labelSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _target, isExpanded: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800),
              items: [
                const DropdownMenuItem(value: 'All Parents', child: Text('ALL PARENTS')),
                ...routes.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.routeName} PARENTS'.toUpperCase()))),
              ],
              onChanged: (v) => setState(() => _target = v!),
            )),
          ),
          const SizedBox(height: 16),
          // Message textarea (dark bg for broadcast like React)
          Container(
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: _msgCtrl, maxLines: 5,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none, contentPadding: const EdgeInsets.all(20)),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(_msgType == 'Emergency Alert' ? Icons.warning_rounded : Icons.info_rounded,
                size: 14, color: _msgType == 'Emergency Alert' ? AppColors.danger : AppColors.blue500),
            const SizedBox(width: 4),
            Text(_msgType == 'Emergency Alert' ? 'PRIORITY: CRITICAL' : 'IN-APP NOTIFICATION',
                style: AppTheme.labelXs.copyWith(color: _msgType == 'Emergency Alert' ? AppColors.danger : AppColors.slate400)),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 52, child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _sendBroadcast, style: AppTheme.primaryButton,
              icon: _sending ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text('SEND BROADCAST', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
          )),
        ]),
      ),
      const SizedBox(height: 20),

      // Payment Confirmations
      if (paymentNotifs.isNotEmpty) ...[
        Text('PAYMENT CONFIRMATIONS', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
        const SizedBox(height: 8),
        ...paymentNotifs.map((n) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.slate100)),
          child: Row(children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)),
              Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate500)),
              Text(Formatters.relativeTime(n.createdAt).toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate300)),
            ])),
          ]),
        )),
        const SizedBox(height: 20),
      ],

      // Recent broadcasts
      Text('RECENT BROADCASTS', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
      const SizedBox(height: 8),
      if (recentBroadcasts.isEmpty)
        Text('NO BROADCASTS YET', style: AppTheme.labelSmall)
      else
        ...recentBroadcasts.map((n) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.slate100)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: n.type == 'WARNING' ? AppColors.danger.withOpacity(0.1) : n.type == 'FEE_DUE' ? AppColors.warning.withOpacity(0.1) : AppColors.blue500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
              child: Text(n.type, style: AppTheme.labelXs.copyWith(
                  color: n.type == 'WARNING' ? AppColors.danger : n.type == 'FEE_DUE' ? AppColors.warning : AppColors.blue500)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(n.title, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800))),
            Text(Formatters.relativeTime(n.createdAt).toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate300)),
          ]),
        )),
    ]));
  }

  // ===== CHAT TAB =====
  Widget _buildChatTab() {
    final parentMessages = _chatMessages.where((m) => !(m['title'] ?? '').toString().contains('[CHAT] Admin')).toList();
    if (parentMessages.isEmpty) return const EmptyState(icon: Icons.chat_rounded, title: 'NO PARENT MESSAGES');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parentMessages.length,
      itemBuilder: (_, i) {
        final m = parentMessages[i];
        final parentName = (m['title'] ?? '').toString().replaceAll('[CHAT]', '').trim();
        final userId = m['user_id'] ?? '';
        _replyCtrls.putIfAbsent(userId, () => TextEditingController());

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate100)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(parentName.toUpperCase(), style: AppTheme.labelSmall.copyWith(color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(m['message'] ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate700)),
            const SizedBox(height: 4),
            Text(Formatters.relativeTime(DateTime.tryParse(m['created_at'] ?? '') ?? DateTime.now()).toUpperCase(),
                style: AppTheme.labelXs.copyWith(color: AppColors.slate300)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(
                controller: _replyCtrls[userId],
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Reply...', hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.slate400),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), isDense: true),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _replyChat(userId, parentName, _replyCtrls[userId]?.text ?? ''),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send_rounded, size: 16, color: Colors.white)),
              ),
            ]),
          ]),
        );
      },
    );
  }

  // ===== AUDIT LOGS TAB =====
  Widget _buildAuditLogsTab() {
    final filtered = _auditSearch.isEmpty ? _auditLogs : _auditLogs.where((l) {
      final q = _auditSearch.toLowerCase();
      return (l['action'] ?? '').toString().toLowerCase().contains(q) ||
          (l['entity_type'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: TextField(
        onChanged: (v) => setState(() => _auditSearch = v),
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: AppTheme.inputDecoration('SEARCH AUDIT LOGS', icon: Icons.search_rounded),
      )),
      Expanded(
        child: _auditLoading ? const MiniLoader() : filtered.isEmpty
            ? const EmptyState(icon: Icons.history_rounded, title: 'NO AUDIT LOGS')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final log = filtered[i];
                  final action = (log['action'] ?? '').toString();
                  final entityType = (log['entity_type'] ?? '').toString();
                  final entityId = (log['entity_id'] ?? '').toString();
                  final adminName = log['profiles']?['full_name'] ?? 'System';
                  final createdAt = DateTime.tryParse(log['created_at'] ?? '') ?? DateTime.now();

                  // Category badge
                  String category; Color catColor;
                  if (action.contains('PAYMENT') || action.contains('FEE') || action.contains('DUE')) {
                    category = 'FINANCE'; catColor = AppColors.success;
                  } else if (action.contains('DELETE') || action.contains('DROP') || action.contains('CRITICAL')) {
                    category = 'CRITICAL'; catColor = AppColors.danger;
                  } else if (action.contains('STUDENT') || action.contains('PARENT') || action.contains('PROFILE')) {
                    category = 'DATA'; catColor = AppColors.warning;
                  } else {
                    category = 'SYSTEM'; catColor = AppColors.blue500;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate100)),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: catColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(category, style: GoogleFonts.plusJakartaSans(
                          fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: catColor)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(action, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                        Text('$entityType — ${entityId.length > 8 ? entityId.substring(0, 8) : entityId}'.toUpperCase(),
                            style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 20, height: 20,
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                            child: Center(child: Text(adminName.toString().isNotEmpty ? adminName[0].toUpperCase() : 'S',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)))),
                          const SizedBox(width: 4),
                          Text(adminName.toString().split(' ').first.toUpperCase(),
                              style: AppTheme.labelXs.copyWith(color: AppColors.slate500)),
                        ]),
                        const SizedBox(height: 2),
                        Text(Formatters.relativeTime(createdAt).toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate300)),
                      ]),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _msgCtrl.dispose(); _chatSub?.cancel();
    for (final c in _replyCtrls.values) c.dispose();
    super.dispose();
  }
}
