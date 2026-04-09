import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _cutoffCtrl = TextEditingController(text: '${AppConstants.defaultCutoffDay}');
  final _graceCtrl = TextEditingController(text: '${AppConstants.defaultGracePeriod}');
  final _penaltyCtrl = TextEditingController(text: '${AppConstants.defaultDailyPenalty.toInt()}');
  final _maxPenaltyCtrl = TextEditingController(text: '${AppConstants.defaultMaxPenalty.toInt()}');
  final _upiIdCtrl = TextEditingController();
  bool _strictNoSkip = AppConstants.defaultStrictNoSkip;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Profile Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                  (auth.user?.fullName.isNotEmpty ?? false) ? auth.user!.fullName[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(auth.user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(auth.user?.isSuperAdmin ?? false ? 'Super Admin' : 'Admin',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              ])),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // Fee Settings
        const Text('Fee Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: _settingField('Cutoff Day', _cutoffCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _settingField('Grace Period (days)', _graceCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _settingField('Daily Penalty (₹)', _penaltyCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _settingField('Max Penalty (₹)', _maxPenaltyCtrl)),
            ]),
            const SizedBox(height: 12),
            _settingField('Admin UPI ID', _upiIdCtrl),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Strict No-Skip Mode'),
              subtitle: const Text('Require sequential month payments'),
              value: _strictNoSkip,
              onChanged: (v) => setState(() => _strictNoSkip = v),
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        )),
        const SizedBox(height: 16),

        SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('Save Settings'),
          ),
        ),
        const SizedBox(height: 24),

        // System Info
        const Text('System Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _infoRow('App Version', '1.0.0'),
            _infoRow('Platform', 'Flutter Mobile'),
            _infoRow('Backend', 'Supabase + Render'),
          ]),
        )),
      ]),
    );
  }

  Widget _settingField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  @override
  void dispose() {
    _cutoffCtrl.dispose(); _graceCtrl.dispose();
    _penaltyCtrl.dispose(); _maxPenaltyCtrl.dispose(); _upiIdCtrl.dispose();
    super.dispose();
  }
}
