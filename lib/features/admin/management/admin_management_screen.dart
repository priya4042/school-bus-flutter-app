import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  void initState() {
    super.initState();
    context.read<AdminProvider>().fetchAdmins();
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AdminProvider>();
    final ok = await prov.createAdmin(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role: _role,
    );
    if (ok && mounted) {
      setState(() => _showForm = false);
      _nameCtrl.clear(); _emailCtrl.clear(); _passCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin created'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    if (_showForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(onPressed: () => setState(() => _showForm = false), icon: const Icon(Icons.arrow_back)),
              const Text('Provision New Admin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role Level'),
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text('Standard Bus Admin')),
                DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Bus Admin')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _passCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Initial Password'),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Required';
                  if (v!.length < 8) return 'Min 8 characters';
                  return null;
                }),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(onPressed: _createAdmin, child: const Text('Create Admin Account'))),
          ],
        )),
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchAdmins(),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('${prov.admins.length} Admins', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('New Admin'),
            ),
          ]),
        ),
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : prov.admins.isEmpty
                  ? const EmptyState(icon: Icons.admin_panel_settings_outlined, title: 'No admins')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: prov.admins.length,
                      itemBuilder: (_, i) {
                        final a = prov.admins[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(a.fullName.isNotEmpty ? a.fullName[0].toUpperCase() : 'A',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(a.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(a.email, style: const TextStyle(fontSize: 13)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: a.isSuperAdmin ? AppColors.accentLight.withOpacity(0.1) : AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                a.isSuperAdmin ? 'Super Admin' : 'Admin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: a.isSuperAdmin ? AppColors.accentLight : AppColors.info,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }
}
