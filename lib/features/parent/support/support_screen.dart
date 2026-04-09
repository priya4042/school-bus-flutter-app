import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';
  bool _showTicketForm = false;
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'Medium';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  final _faqs = [
    {'q': 'How do I pay my bus fees?', 'a': 'Go to the Fees tab, find the pending month, and tap "Pay Now". You can pay via UPI, card, or net banking.'},
    {'q': 'Why is my month locked?', 'a': 'You need to pay previous months first. The system enforces sequential payment to prevent arrears.'},
    {'q': 'How do I download a receipt?', 'a': 'Go to Receipts tab, tap on any paid month to generate and share a PDF receipt.'},
    {'q': 'How do I track my child\'s bus?', 'a': 'Go to Live Tracking tab to see real-time bus location on the map.'},
    {'q': 'What if my child\'s attendance is wrong?', 'a': 'Contact the bus admin via Support ticket or call to correct attendance records.'},
    {'q': 'How do I update my profile?', 'a': 'Go to Settings > Edit Profile to update your name, email, phone, or avatar.'},
    {'q': 'What is a late fee?', 'a': 'A daily penalty applied after the grace period if fees are not paid by the due date.'},
    {'q': 'How do I link another child?', 'a': 'Go to Student Profile and tap "Add Child" with the child\'s admission number.'},
  ];

  Future<void> _submitTicket() async {
    if (_subjectCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;

    final auth = context.read<AppAuthProvider>();
    // Send as notification to admins
    final notifProv = context.read<NotificationProvider>();
    await notifProv.broadcastToParents(
      title: 'Support Ticket: ${_subjectCtrl.text}',
      message: '[TICKET] Priority: $_priority\n${_descCtrl.text}\n\nFrom: ${auth.user?.fullName ?? "Parent"}',
      type: 'INFO',
    );

    if (mounted) {
      setState(() => _showTicketForm = false);
      _subjectCtrl.clear();
      _descCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket submitted! We\'ll respond within 24h.'),
            backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(controller: _tabCtrl, tabs: const [
        Tab(text: 'FAQ'),
        Tab(text: 'Contact'),
      ]),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _buildFaq(),
        _buildContact(),
      ])),
    ]);
  }

  Widget _buildFaq() {
    final filtered = _faqs.where((f) {
      if (_search.isEmpty) return true;
      return f['q']!.toLowerCase().contains(_search.toLowerCase()) ||
          f['a']!.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: const InputDecoration(
            hintText: 'Search FAQs...',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        ...filtered.map((f) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline, size: 20, color: AppColors.info),
            title: Text(f['q']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(f['a']!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
            ],
          ),
        )),
      ]),
    );
  }

  Widget _buildContact() {
    if (_showTicketForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(onPressed: () => setState(() => _showTicketForm = false),
                icon: const Icon(Icons.arrow_back)),
            const Text('Submit Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          TextFormField(controller: _subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: ['Low', 'Medium', 'High', 'Urgent']
                .map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _descCtrl, maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe your issue...')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: _submitTicket,
              icon: const Icon(Icons.send),
              label: const Text('Submit Ticket'),
            )),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Contact channels
        _contactCard(Icons.edit_note, 'Submit a Ticket', 'Get help with any issue',
            AppColors.primary, () => setState(() => _showTicketForm = true)),
        _contactCard(Icons.phone, 'Call Support', 'Speak to our team directly',
            AppColors.success, () => launchUrl(Uri.parse('tel:+911234567890'))),
        _contactCard(Icons.email, 'Email Us', 'support@buswaypro.com',
            AppColors.info, () => launchUrl(Uri.parse('mailto:support@buswaypro.com'))),
        const SizedBox(height: 24),

        // Quick links
        const Align(alignment: Alignment.centerLeft,
            child: Text('Documentation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        const SizedBox(height: 12),
        _docLink('User Manual', Icons.book),
        _docLink('Safety Policy', Icons.shield),
        _docLink('Terms of Service', Icons.description),
        _docLink('Privacy Policy', Icons.privacy_tip),
      ]),
    );
  }

  Widget _contactCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _docLink(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(icon, size: 20, color: AppColors.textSecondary),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.textSecondary),
        dense: true,
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _subjectCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }
}
