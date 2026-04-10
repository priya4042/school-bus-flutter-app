import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});
  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  bool _showForm = false;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'ADMIN';

  @override
  void initState() { super.initState(); context.read<AdminProvider>().fetchAdmins(); }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AdminProvider>().createAdmin(
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(), role: _role);
    if (ok && mounted) {
      setState(() => _showForm = false);
      _nameCtrl.clear(); _emailCtrl.clear(); _passCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ADMIN PROVISIONED'), backgroundColor: AppColors.success));
    }
  }

  Future<void> _toggleStatus(String adminId, String name, bool currentlyActive) async {
    final action = currentlyActive ? 'DEACTIVATE' : 'ACTIVATE';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('$action $name?', style: AppTheme.headingSmall),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(backgroundColor: currentlyActive ? AppColors.danger : AppColors.success),
          child: Text(action)),
      ],
    ));
    if (ok == true) {
      // Note: is_active field may not exist in all setups; this updates the profile
      try {
        await Supabase.instance.client.from('profiles')
            .update({'is_active': !currentlyActive}).eq('id', adminId);
        context.read<AdminProvider>().fetchAdmins();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ADMIN ${currentlyActive ? "DEACTIVATED" : "ACTIVATED"}'), backgroundColor: AppColors.success));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    if (_showForm) {
      return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(onPressed: () => setState(() => _showForm = false), icon: const Icon(Icons.arrow_back_rounded)),
            Text('PROVISION NEW ADMIN', style: AppTheme.headingSmall),
          ]),
          const SizedBox(height: 20),
          TextFormField(controller: _nameCtrl,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
            decoration: AppTheme.inputDecoration('FULL NAME', icon: Icons.person_rounded),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
          const SizedBox(height: 16),
          TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
            decoration: AppTheme.inputDecoration('EMAIL ADDRESS', icon: Icons.email_rounded),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _role,
            decoration: AppTheme.inputDecoration('ROLE LEVEL'),
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
            items: [
              DropdownMenuItem(value: 'ADMIN', child: Text('STANDARD BUS ADMIN', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700))),
              DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('SUPER BUS ADMIN', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700))),
            ],
            onChanged: (v) => setState(() => _role = v!)),
          const SizedBox(height: 16),
          TextFormField(controller: _passCtrl, obscureText: true,
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
            decoration: AppTheme.inputDecoration('INITIAL PASSWORD', icon: Icons.lock_rounded),
            validator: (v) { if (v?.isEmpty ?? true) return 'Required'; if (v!.length < 8) return 'Min 8 characters'; return null; }),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52, child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
            child: ElevatedButton(onPressed: _createAdmin, style: AppTheme.primaryButton,
              child: Text('CREATE ADMIN ACCOUNT', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
          )),
        ]),
      ));
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchAdmins(),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Text('${prov.admins.length} ADMINS', style: AppTheme.labelStyle.copyWith(color: AppColors.slate600)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showForm = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text('NEW ADMIN', style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
              ]),
            ),
          ),
        ])),
        Expanded(
          child: prov.isLoading ? const MiniLoader() : prov.admins.isEmpty
              ? const EmptyState(icon: Icons.admin_panel_settings_rounded, title: 'NO ADMINS')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: prov.admins.length,
                  itemBuilder: (_, i) {
                    final a = prov.admins[i];
                    // Assume active if no explicit field
                    const isActive = true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.slate100)),
                      child: Row(children: [
                        Container(width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.slate900, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(a.fullName.isNotEmpty ? a.fullName[0].toUpperCase() : 'A',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.fullName.toUpperCase(), style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
                          Text(a.email.toLowerCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: a.isSuperAdmin ? AppColors.indigo500.withOpacity(0.1) : AppColors.blue500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                            child: Text(a.isSuperAdmin ? 'SUPER ADMIN' : 'STANDARD',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1,
                                    color: a.isSuperAdmin ? AppColors.indigo500 : AppColors.blue500)),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _toggleStatus(a.id, a.fullName, isActive),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                              child: Text(isActive ? 'ACTIVE' : 'DISABLED',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1,
                                      color: isActive ? AppColors.success : AppColors.danger)),
                            ),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }
}
