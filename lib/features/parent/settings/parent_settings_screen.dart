import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/avatar_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stylish_loader.dart';

/// Parent Settings — supports multi-tab mode (default) AND single-tab mode
/// (when accessed from sidebar submenu like Profile / Password / Language)
class ParentSettingsScreen extends StatefulWidget {
  /// 0 = Profile, 1 = Security, 2 = Language
  final int initialTab;
  /// When true, only the selected tab content is shown (no tab bar)
  final bool singleTab;
  const ParentSettingsScreen({super.key, this.initialTab = 0, this.singleTab = false});

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
  bool _savingProfile = false;
  bool _changingPassword = false;

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

  Future<void> _pickAndUploadAvatar() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    final file = await AvatarService.pickImage();
    if (file == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await AvatarService.uploadAvatar(auth.user!.id, file);
      if (url != null) {
        await auth.updateProfile({'avatar_url': url});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated'), backgroundColor: AppColors.success),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await AvatarService.removeAvatar(auth.user!.id);
    await auth.updateProfile({'avatar_url': null});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar removed'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final auth = context.read<AppAuthProvider>();
    await auth.updateProfile({
      'full_name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone_number': _phoneCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _savingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 8 characters'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _changingPassword = true);
    try {
      await context.read<AppAuthProvider>().changePassword(_newPassCtrl.text);
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;

    // ===== SINGLE TAB MODE — render the selected page directly =====
    if (widget.singleTab) {
      return Column(children: [
        // Page header with title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              widget.initialTab == 0
                  ? t('edit_profile')
                  : widget.initialTab == 1
                      ? t('password_reset')
                      : t('select_language'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.initialTab == 0
                  ? t('update_info')
                  : widget.initialTab == 1
                      ? t('change_password')
                      : t('choose_language'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ]),
        ),
        // Render only the selected page content
        Expanded(
          child: widget.initialTab == 0
              ? _buildProfileTab(t)
              : widget.initialTab == 1
                  ? _buildSecurityTab(t)
                  : _buildLanguageTab(t),
        ),
      ]);
    }

    // ===== MULTI-TAB MODE (default — when accessed via topbar dropdown) =====
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.slate200.withOpacity(0.5)),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate400,
          tabs: [
            Tab(text: t('profile')),
            Tab(text: t('password_reset')),
            Tab(text: t('language')),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildProfileTab(t),
            _buildSecurityTab(t),
            _buildLanguageTab(t),
          ],
        ),
      ),
    ]);
  }

  // ===== PROFILE TAB =====
  Widget _buildProfileTab(String Function(String) t) {
    final auth = context.watch<AppAuthProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardXlDecoration,
        child: Column(children: [
          // Avatar with upload + remove
          Row(children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
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
                            errorBuilder: (_, __, ___) => _initialAvatar(auth.user!.fullName),
                          )
                        : _initialAvatar(auth.user!.fullName),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: _uploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                if (auth.user?.avatarUrl != null && auth.user!.avatarUrl!.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: _removeAvatar,
                      child: Container(
                        width: 28,
                        height: 28,
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
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  auth.user?.fullName ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${auth.user?.isParent ?? true ? t('profile') : 'User'} · ${auth.user?.createdAt != null ? Formatters.date(auth.user!.createdAt!) : ""}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap camera to update photo',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate400,
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),
          _field(t('full_name'), _nameCtrl, Icons.person_rounded),
          _field(t('email'), _emailCtrl, Icons.email_rounded, inputType: TextInputType.emailAddress),
          _field(t('phone_number'), _phoneCtrl, Icons.phone_rounded, inputType: TextInputType.phone),
          TextField(
            readOnly: true,
            decoration: AppTheme.inputDecoration(t('admission_number')).copyWith(
              prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.slate400, size: 20),
            ),
            controller: TextEditingController(text: auth.user?.admissionNumber ?? ''),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.primaryButtonShadow(),
              ),
              child: ElevatedButton.icon(
                onPressed: _savingProfile ? null : _saveProfile,
                style: AppTheme.primaryButton,
                icon: _savingProfile
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  t('save'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ===== SECURITY TAB =====
  Widget _buildSecurityTab(String Function(String) t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardXlDecoration,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  t('change_password'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min 8 characters required',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 24),
          TextField(
            controller: _newPassCtrl,
            obscureText: _obscure,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate800,
            ),
            decoration: AppTheme.inputDecoration('New Password', icon: Icons.lock_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.slate400,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: _obscureConfirm,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate800,
            ),
            decoration: AppTheme.inputDecoration('Confirm Password', icon: Icons.lock_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.slate400,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_confirmPassCtrl.text.isNotEmpty && _newPassCtrl.text != _confirmPassCtrl.text) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
              const SizedBox(width: 4),
              Text(
                'Passwords do not match',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ]),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.primaryButtonShadow(),
              ),
              child: ElevatedButton.icon(
                onPressed: _changingPassword ? null : _changePassword,
                style: AppTheme.primaryButton,
                icon: _changingPassword
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Update Password',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ===== LANGUAGE TAB =====
  Widget _buildLanguageTab(String Function(String) t) {
    return Consumer<LocaleProvider>(
      builder: (context, locale, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _languages.map((l) {
            final isSelected = locale.lang == l['code'];
            final isAvailable = l['available'] == 'true';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.slate100,
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)]
                    : null,
              ),
              child: ListTile(
                leading: Text(l['flag']!, style: const TextStyle(fontSize: 28)),
                title: Text(
                  l['name']!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
                subtitle: Text(
                  isAvailable ? l['sub']! : '${l['sub']!} · Coming soon',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate400,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                    : null,
                onTap: isAvailable
                    ? () async {
                        await locale.setLang(l['code']!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l['code'] == 'hi'
                                  ? 'भाषा हिन्दी में बदल दी गई'
                                  : 'Language changed to English'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    : null,
                enabled: isAvailable,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _initialAvatar(String fullName) {
    return Container(
      color: AppColors.slate50,
      alignment: Alignment.center,
      child: Text(
        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.slate300,
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.slate800,
        ),
        decoration: AppTheme.inputDecoration(label, icon: icon),
      ),
    );
  }

  static const _languages = [
    {'code': 'en', 'name': 'English', 'sub': 'Default', 'flag': '🇬🇧', 'available': 'true'},
    {'code': 'hi', 'name': 'हिन्दी', 'sub': 'Hindi', 'flag': '🇮🇳', 'available': 'true'},
    {'code': 'es', 'name': 'Español', 'sub': 'Spanish', 'flag': '🇪🇸', 'available': 'false'},
    {'code': 'fr', 'name': 'Français', 'sub': 'French', 'flag': '🇫🇷', 'available': 'false'},
    {'code': 'ar', 'name': 'العربية', 'sub': 'Arabic', 'flag': '🇸🇦', 'available': 'false'},
    {'code': 'pt', 'name': 'Português', 'sub': 'Portuguese', 'flag': '🇧🇷', 'available': 'false'},
    {'code': 'zh', 'name': '中文', 'sub': 'Chinese', 'flag': '🇨🇳', 'available': 'false'},
    {'code': 'ja', 'name': '日本語', 'sub': 'Japanese', 'flag': '🇯🇵', 'available': 'false'},
  ];

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}
