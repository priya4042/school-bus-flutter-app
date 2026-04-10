import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/avatar_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';

class ParentSettingsScreen extends StatefulWidget {
  final int initialTab;
  const ParentSettingsScreen({super.key, this.initialTab = 0});
  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _uploadingAvatar = false;
  String _selectedLang = 'en';

  Future<void> _pickAndUploadAvatar() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;

    final file = await AvatarService.pickImage();
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await AvatarService.uploadAvatar(auth.user!.id, file);
      if (url != null) {
        // Reload profile so avatar appears in topbar
        await auth.updateProfile({'avatar_url': url});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated'), backgroundColor: AppColors.success),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload avatar'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('REMOVE AVATAR?', style: TextStyle(
          fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w900)),
        content: const Text('Your profile will show your initial instead.',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(
              fontFamily: 'PlusJakartaSans', fontSize: 11, fontWeight: FontWeight.w900,
              letterSpacing: 2, color: AppColors.slate500))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('REMOVE', style: TextStyle(
              fontFamily: 'PlusJakartaSans', fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await AvatarService.removeAvatar(auth.user!.id);
      await auth.updateProfile({'avatar_url': null});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar removed'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    final auth = context.read<AppAuthProvider>();
    if (auth.user != null) {
      _nameCtrl.text = auth.user!.fullName;
      _emailCtrl.text = auth.user!.email;
      _phoneCtrl.text = auth.user!.phoneNumber ?? '';
    }
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AppAuthProvider>();
    await auth.updateProfile({
      'full_name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success));
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum 8 characters'), backgroundColor: AppColors.danger));
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.danger));
      return;
    }
    try {
      await context.read<AppAuthProvider>().changePassword(_newPassCtrl.text);
      _newPassCtrl.clear(); _confirmPassCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Column(children: [
      // Tab bar
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200.withOpacity(0.5))),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          unselectedLabelStyle: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate400,
          tabs: const [Tab(text: 'PROFILE'), Tab(text: 'SECURITY'), Tab(text: 'LANGUAGE')],
        ),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        // ===== PROFILE TAB =====
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardXlDecoration,
          child: Column(children: [
            // Avatar section with upload + remove
            Row(children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: auth.user?.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty
                          ? Image.network(
                              auth.user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  (auth.user!.fullName.isNotEmpty ? auth.user!.fullName[0] : 'U').toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.slate300,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                (auth.user?.fullName.isNotEmpty ?? false) ? auth.user!.fullName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.slate300,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Camera button (bottom-right)
                  Positioned(
                    bottom: -4, right: -4,
                    child: GestureDetector(
                      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                        ),
                        child: _uploadingAvatar
                            ? const Padding(padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  // Remove button (top-right) - only show if avatar exists
                  if (auth.user?.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty)
                    Positioned(
                      top: -4, right: -4,
                      child: GestureDetector(
                        onTap: _removeAvatar,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: AppColors.danger.withOpacity(0.3), blurRadius: 8)],
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.user?.fullName ?? '', style: TextStyle(fontFamily: 'PlusJakartaSans',
                  fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate900)),
                const SizedBox(height: 4),
                Text('${auth.user?.isParent ?? true ? "PARENT" : "USER"} • SINCE ${auth.user?.createdAt != null ? Formatters.date(auth.user!.createdAt!).toUpperCase() : "N/A"}',
                    style: AppTheme.labelXs.copyWith(color: AppColors.slate500)),
                const SizedBox(height: 6),
                Text('Tap camera to update photo',
                    style: TextStyle(fontFamily: 'PlusJakartaSans',
                      fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate400)),
              ])),
            ]),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),
            // Form fields
            _field('FULL NAME', _nameCtrl, Icons.person_rounded),
            _field('EMAIL', _emailCtrl, Icons.email_rounded, inputType: TextInputType.emailAddress),
            _field('PHONE NUMBER', _phoneCtrl, Icons.phone_rounded, inputType: TextInputType.phone),
            TextField(
              readOnly: true,
              decoration: AppTheme.inputDecoration('ADMISSION NUMBER').copyWith(
                prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.slate400, size: 20)),
              controller: TextEditingController(text: auth.user?.admissionNumber ?? ''),
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate400),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
              child: ElevatedButton.icon(
                onPressed: _saveProfile, style: AppTheme.primaryButton,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('SAVE CHANGES', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            )),
          ]),
        )),

        // ===== SECURITY TAB =====
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.cardXlDecoration,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CHANGE PASSWORD', style: AppTheme.headingSmall),
            const SizedBox(height: 20),
            TextField(
              controller: _newPassCtrl,
              obscureText: _obscure,
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
              decoration: AppTheme.inputDecoration('NEW PASSWORD', icon: Icons.lock_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.slate400, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
              decoration: AppTheme.inputDecoration('CONFIRM PASSWORD', icon: Icons.lock_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.slate400, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            if (_confirmPassCtrl.text.isNotEmpty && _newPassCtrl.text != _confirmPassCtrl.text) ...[
              const SizedBox(height: 6),
              Text('PASSWORDS DO NOT MATCH', style: AppTheme.labelSmall.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
              child: ElevatedButton(onPressed: _changePassword, style: AppTheme.primaryButton,
                child: Text('UPDATE PASSWORD', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
            )),
          ]),
        )),

        // ===== LANGUAGE TAB =====
        SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _languages.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedLang == l['code'] ? AppColors.primary : AppColors.slate100,
                width: _selectedLang == l['code'] ? 2 : 1),
              color: _selectedLang == l['code'] ? AppColors.primary.withOpacity(0.05) : Colors.white,
              boxShadow: _selectedLang == l['code'] ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)] : null,
            ),
            child: ListTile(
              leading: Text(l['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(l['name']!, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.slate800)),
              subtitle: l['available'] != 'true'
                  ? Text('COMING SOON', style: AppTheme.labelXs.copyWith(color: AppColors.slate400))
                  : null,
              trailing: _selectedLang == l['code']
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: l['available'] == 'true' ? () => setState(() => _selectedLang = l['code']!) : null,
              enabled: l['available'] == 'true',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          )).toList(),
        )),
      ])),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType inputType = TextInputType.text}) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: TextField(
      controller: ctrl, keyboardType: inputType,
      style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
      decoration: AppTheme.inputDecoration(label, icon: icon),
    ));
  }

  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'available': 'true'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'available': 'true'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'available': 'false'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'available': 'false'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'available': 'false'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷', 'available': 'false'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'available': 'false'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵', 'available': 'false'},
  ];

  @override
  void dispose() { _tabCtrl.dispose(); _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _newPassCtrl.dispose(); _confirmPassCtrl.dispose(); super.dispose(); }
}
