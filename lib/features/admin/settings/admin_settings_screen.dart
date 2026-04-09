import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  // Fee Engine
  final _cutoffCtrl = TextEditingController(text: '${AppConstants.defaultCutoffDay}');
  final _graceCtrl = TextEditingController(text: '${AppConstants.defaultGracePeriod}');
  final _penaltyCtrl = TextEditingController(text: '${AppConstants.defaultDailyPenalty.toInt()}');
  final _maxPenaltyCtrl = TextEditingController(text: '${AppConstants.defaultMaxPenalty.toInt()}');
  final _qrUrlCtrl = TextEditingController();
  final _upiIdCtrl = TextEditingController();
  bool _strictNoSkip = AppConstants.defaultStrictNoSkip;
  bool _enforce2FA = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('busway_fee_settings_v1');
    if (raw != null) {
      try {
        final s = jsonDecode(raw);
        setState(() {
          _cutoffCtrl.text = '${s['cutoffDay'] ?? 10}';
          _graceCtrl.text = '${s['gracePeriod'] ?? 2}';
          _penaltyCtrl.text = '${s['dailyPenalty'] ?? 50}';
          _maxPenaltyCtrl.text = '${s['maxPenalty'] ?? 500}';
          _qrUrlCtrl.text = s['adminPaymentQrUrl'] ?? '';
          _upiIdCtrl.text = s['adminUpiId'] ?? '';
          _strictNoSkip = s['strictNoSkip'] ?? true;
          _enforce2FA = s['enforce2FA'] ?? false;
        });
      } catch (_) {}
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = {
      'cutoffDay': int.tryParse(_cutoffCtrl.text) ?? 10,
      'gracePeriod': int.tryParse(_graceCtrl.text) ?? 2,
      'dailyPenalty': int.tryParse(_penaltyCtrl.text) ?? 50,
      'maxPenalty': int.tryParse(_maxPenaltyCtrl.text) ?? 500,
      'strictNoSkip': _strictNoSkip,
      'enforce2FA': _enforce2FA,
      'adminPaymentQrUrl': _qrUrlCtrl.text.trim(),
      'adminUpiId': _upiIdCtrl.text.trim(),
    };
    await prefs.setString('busway_fee_settings_v1', jsonEncode(settings));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SETTINGS COMMITTED'), backgroundColor: AppColors.success));
  }

  void _resetDefaults() {
    setState(() {
      _cutoffCtrl.text = '10'; _graceCtrl.text = '2'; _penaltyCtrl.text = '50'; _maxPenaltyCtrl.text = '500';
      _strictNoSkip = true; _enforce2FA = false; _qrUrlCtrl.clear(); _upiIdCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

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
          tabs: const [Tab(text: 'FEE ENGINE'), Tab(text: 'SECURITY')],
        ),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        // ===== FEE ENGINE TAB =====
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Profile card
          Container(padding: const EdgeInsets.all(16), decoration: AppTheme.cardDecoration,
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(
                  (auth.user?.fullName.isNotEmpty ?? false) ? auth.user!.fullName[0].toUpperCase() : 'A',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.user?.fullName ?? '', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate800)),
                Text(auth.user?.isSuperAdmin ?? false ? 'SUPER ADMIN' : 'ADMIN',
                    style: AppTheme.labelXs.copyWith(color: AppColors.primary)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          // Fee Lifecycle
          _sectionLabel('FEE LIFECYCLE CONFIGURATION'),
          Container(padding: const EdgeInsets.all(20), decoration: AppTheme.cardLargeDecoration,
            child: Column(children: [
              _settingRow('MONTHLY DUE CUTOFF (DAY)', _cutoffCtrl, 'Payments marked OVERDUE after this day'),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NO-SKIP CONSTRAINT', style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                  Text(_strictNoSkip ? 'STRICT — PARENTS MUST PAY IN ORDER' : 'LAX — ANY MONTH IN ANY ORDER',
                      style: AppTheme.labelXs.copyWith(color: AppColors.slate500)),
                ])),
                Switch(value: _strictNoSkip, onChanged: (v) => setState(() => _strictNoSkip = v),
                    activeColor: AppColors.primary),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Late Fee Engine
          _sectionLabel('LATE FEE CALCULATION ENGINE'),
          Container(padding: const EdgeInsets.all(20), decoration: AppTheme.cardLargeDecoration,
            child: Column(children: [
              _settingRow('GRACE PERIOD (DAYS)', _graceCtrl, 'Days after due date before penalties'),
              const Divider(height: 24),
              _settingRow('DAILY PENALTY RATE (₹)', _penaltyCtrl, 'Rupees per day late'),
              const Divider(height: 24),
              _settingRow('MAX LATE FEE (₹)', _maxPenaltyCtrl, 'Caps total late fee per month'),
            ]),
          ),
          const SizedBox(height: 16),

          // Parent Payment QR
          _sectionLabel('PARENT PAYMENT QR'),
          Container(padding: const EdgeInsets.all(20), decoration: AppTheme.cardLargeDecoration,
            child: Column(children: [
              TextField(controller: _qrUrlCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                decoration: AppTheme.inputDecoration('ADMIN QR IMAGE URL', icon: Icons.qr_code_rounded)),
              const SizedBox(height: 12),
              TextField(controller: _upiIdCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate800),
                decoration: AppTheme.inputDecoration('ADMIN UPI ID', icon: Icons.account_balance_rounded)),
              if (_qrUrlCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  height: 120, width: 120,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Image.network(_qrUrlCtrl.text, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.slate300)))),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 24),

          // Commit / Reset
          Row(children: [
            Expanded(child: SizedBox(height: 52, child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
              child: ElevatedButton.icon(onPressed: _saveSettings, style: AppTheme.primaryButton,
                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text('COMMIT GLOBAL CHANGES', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2))),
            ))),
            const SizedBox(width: 12),
            SizedBox(height: 52, child: ElevatedButton(onPressed: _resetDefaults, style: AppTheme.secondaryButton,
              child: Text('RESET', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)))),
          ]),
          const SizedBox(height: 20),

          // Config vault info
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
              color: AppColors.slate50, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate100)),
            child: Column(children: [
              _infoRow('APP VERSION', '2.4.0'),
              _infoRow('DATABASE', 'CONNECTED'),
              _infoRow('PLATFORM', 'FLUTTER MOBILE'),
              _infoRow('BACKEND', 'SUPABASE + RENDER'),
            ]),
          ),
        ])),

        // ===== SECURITY TAB =====
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Container(
          padding: const EdgeInsets.all(20), decoration: AppTheme.cardLargeDecoration,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ACCESS CONTROL POLICIES', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ENFORCE 2FA', style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                  Text('DRIVERS & TEACHERS REQUIRE OTP LOGIN', style: AppTheme.labelXs.copyWith(color: AppColors.slate500)),
                ])),
                Switch(value: _enforce2FA, onChanged: (v) => setState(() => _enforce2FA = v), activeColor: AppColors.primary),
              ]),
            ),
          ]),
        )),
      ])),
    ]);
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
  );

  Widget _settingRow(String label, TextEditingController ctrl, String hint) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)),
        Text(hint.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
      ])),
      SizedBox(width: 80, child: TextField(controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary),
        decoration: InputDecoration(filled: true, fillColor: AppColors.primary.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2))),
          contentPadding: const EdgeInsets.symmetric(vertical: 12)))),
    ]);
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
      Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)),
    ]),
  );

  @override
  void dispose() {
    _tabCtrl.dispose(); _cutoffCtrl.dispose(); _graceCtrl.dispose();
    _penaltyCtrl.dispose(); _maxPenaltyCtrl.dispose(); _qrUrlCtrl.dispose(); _upiIdCtrl.dispose();
    super.dispose();
  }
}
