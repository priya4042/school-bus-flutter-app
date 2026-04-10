import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _faqSearch = '';
  bool _showTicketForm = false;
  bool _ticketSent = false;
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'MEDIUM';

  final _faqs = [
    {'q': 'How do I pay my bus fees?', 'a': 'Go to Fees tab, find the pending month, tap "Pay Now". Pay via UPI, card, or net banking.'},
    {'q': 'Why is my month locked?', 'a': 'You need to pay previous months first. The system enforces sequential payments.'},
    {'q': 'How do I download a receipt?', 'a': 'Go to Receipts tab, tap on any paid month to generate and share a PDF receipt.'},
    {'q': 'How do I track my child\'s bus?', 'a': 'Go to Live Tracking tab to see real-time bus location on the map.'},
    {'q': 'What if attendance is wrong?', 'a': 'Contact the bus admin via Support ticket or call to correct attendance records.'},
    {'q': 'How do I update my profile?', 'a': 'Go to Settings > Profile to update your name, email, phone, or avatar.'},
  ];

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }

  Future<void> _submitTicket() async {
    if (_subjectCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    final auth = context.read<AppAuthProvider>();
    final prov = context.read<NotificationProvider>();
    await prov.broadcastToParents(
      title: 'Support Ticket: ${_subjectCtrl.text}',
      message: '[TICKET] Priority: $_priority\n${_descCtrl.text}\n\nFrom: ${auth.user?.fullName ?? "Parent"}',
      type: 'INFO',
    );
    _subjectCtrl.clear(); _descCtrl.clear();
    setState(() { _showTicketForm = false; _ticketSent = true; });
    Future.delayed(const Duration(seconds: 4), () { if (mounted) setState(() => _ticketSent = false); });
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
          labelStyle: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          unselectedLabelStyle: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.slate400,
          tabs: const [Tab(text: 'CONTACT'), Tab(text: 'FAQ')],
        ),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        // ===== CONTACT TAB =====
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
          // Success banner
          if (_ticketSent) Container(
            padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.2))),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TICKET SUBMITTED', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.emerald600)),
                Text('WE\'LL RESPOND WITHIN 24H', style: AppTheme.labelXs.copyWith(color: AppColors.emerald600)),
              ])),
            ]),
          ),

          if (_showTicketForm)
            _buildTicketForm()
          else ...[
            // Hero dark card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.slate950,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
              ),
              child: Column(children: [
                Text('HOW CAN WE HELP?', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white)),
                const SizedBox(height: 8),
                Text('SEARCH OUR HELP CENTER', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white.withOpacity(0.4))),
              ]),
            ),
            const SizedBox(height: 16),

            // 3 contact cards
            _contactCard(Icons.edit_note_rounded, 'SUBMIT A TICKET', 'GET HELP WITH ANY ISSUE',
                AppColors.primary, () => setState(() => _showTicketForm = true)),
            _contactCard(Icons.phone_rounded, 'CALL SUPPORT', 'SPEAK TO OUR TEAM',
                AppColors.success, () => launchUrl(Uri.parse('tel:+911234567890'))),
            _contactCard(Icons.email_rounded, 'EMAIL US', 'SUPPORT@BUSWAYPRO.COM',
                AppColors.blue500, () => launchUrl(Uri.parse('mailto:support@buswaypro.com'))),
          ],
        ])),

        // ===== FAQ TAB =====
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            onChanged: (v) => setState(() => _faqSearch = v),
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, fontWeight: FontWeight.w700),
            decoration: AppTheme.inputDecoration('SEARCH FAQS', icon: Icons.search_rounded),
          ),
          const SizedBox(height: 16),
          ..._faqs.where((f) {
            if (_faqSearch.isEmpty) return true;
            return f['q']!.toLowerCase().contains(_faqSearch.toLowerCase()) ||
                f['a']!.toLowerCase().contains(_faqSearch.toLowerCase());
          }).map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate100)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)]),
                  child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 18)),
                title: Text(f['q']!.toUpperCase(), style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [Text(f['a']!, style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.slate400, height: 1.8))],
              ),
            ),
          )),
          const SizedBox(height: 24),
          Text('DOCUMENTATION', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
          const SizedBox(height: 12),
          Row(children: [
            _docLink(Icons.book_rounded, 'MANUAL', AppColors.blue500),
            const SizedBox(width: 8),
            _docLink(Icons.shield_rounded, 'SAFETY', AppColors.success),
            const SizedBox(width: 8),
            _docLink(Icons.description_rounded, 'TERMS', AppColors.slate500),
            const SizedBox(width: 8),
            _docLink(Icons.privacy_tip_rounded, 'PRIVACY', AppColors.danger),
          ]),
        ])),
      ])),
    ]);
  }

  Widget _buildTicketForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardXlDecoration,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SUBMIT TICKET', style: AppTheme.headingSmall),
          GestureDetector(
            onTap: () => setState(() => _showTicketForm = false),
            child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.close_rounded, color: AppColors.slate500, size: 18)),
          ),
        ]),
        const SizedBox(height: 20),
        TextField(controller: _subjectCtrl, decoration: AppTheme.inputDecoration('SUBJECT'),
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800)),
        const SizedBox(height: 12),
        Text('PRIORITY', style: AppTheme.labelSmall),
        const SizedBox(height: 8),
        Row(children: ['LOW', 'MEDIUM', 'HIGH'].map((p) {
          final sel = _priority == p;
          Color c;
          switch (p) { case 'HIGH': c = AppColors.danger; break; case 'LOW': c = AppColors.success; break; default: c = AppColors.warning; }
          return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? c : AppColors.slate100,
                borderRadius: BorderRadius.circular(12)),
              child: Text(p, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
                  color: sel ? Colors.white : AppColors.slate500)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 16),
        TextField(controller: _descCtrl, maxLines: 5,
            decoration: AppTheme.inputDecoration('DESCRIBE YOUR ISSUE'),
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: SizedBox(height: 52, child: ElevatedButton(onPressed: () => setState(() => _showTicketForm = false),
              style: AppTheme.secondaryButton, child: const Text('CANCEL')))),
          const SizedBox(width: 12),
          Expanded(child: SizedBox(height: 52, child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
            child: ElevatedButton.icon(onPressed: _submitTicket, style: AppTheme.primaryButton,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text('SUBMIT', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
          ))),
        ]),
      ]),
    );
  }

  Widget _contactCard(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate100)),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate900)),
            Text(sub, style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate300),
        ]),
      ),
    );
  }

  Widget _docLink(IconData icon, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100)),
      child: Column(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.slate600)),
      ]),
    ));
  }

  @override
  void dispose() { _tabCtrl.dispose(); _subjectCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }
}
