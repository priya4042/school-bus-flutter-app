import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error),
      );
      return;
    }

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
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Column(children: [
      TabBar(controller: _tabCtrl, tabs: const [
        Tab(text: 'Profile'),
        Tab(text: 'Security'),
        Tab(text: 'Language'),
      ]),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        // Profile
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Avatar
            Center(child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text(
                  (auth.user?.fullName.isNotEmpty ?? false) ? auth.user!.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(auth.user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text(auth.user?.role == UserRole.parent ? 'Parent' : 'User',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ])),
            const SizedBox(height: 24),

            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outlined))),
            const SizedBox(height: 16),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),
            TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: auth.user?.admissionNumber,
              decoration: const InputDecoration(labelText: 'Admission Number', prefixIcon: Icon(Icons.badge_outlined)),
              readOnly: true,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(onPressed: _saveProfile, child: const Text('Save Changes'))),
          ]),
        ),

        // Security
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPassCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(onPressed: _changePassword, child: const Text('Update Password'))),
          ]),
        ),

        // Language
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ..._languages.map((l) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedLang == l['code'] ? AppColors.primary : AppColors.border,
                  width: _selectedLang == l['code'] ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Text(l['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(l['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: l['available'] == 'true'
                    ? null
                    : const Text('Coming soon', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                trailing: _selectedLang == l['code']
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: l['available'] == 'true'
                    ? () => setState(() => _selectedLang = l['code']!)
                    : null,
                enabled: l['available'] == 'true',
              ),
            )),
          ]),
        ),
      ])),
    ]);
  }

  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'available': 'true'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'available': 'true'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'available': 'false'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'available': 'false'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'available': 'false'},
  ];

  @override
  void dispose() {
    _tabCtrl.dispose(); _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _newPassCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }
}

