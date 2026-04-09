import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isParentMode = true;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final id = _identifierCtrl.text.trim();
    final pw = _passwordCtrl.text;

    bool success;
    if (_isParentMode) {
      success = id.contains('@')
          ? await auth.loginWithEmail(id, pw)
          : await auth.loginWithAdmission(id, pw);
    } else {
      success = id.contains('@')
          ? await auth.loginWithEmail(id, pw)
          : await auth.loginWithPhone(id, pw);
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Login failed'),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [AppColors.slate800, AppColors.slate900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isParentMode ? AppColors.primary : AppColors.slate900,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(children: [
                        // Logo
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: _isParentMode ? AppColors.primary : AppColors.slate900,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_isParentMode ? AppColors.primary : AppColors.slate900).withOpacity(0.3),
                                blurRadius: 20, offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text('BUSWAY PRO', style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate800)),
                        const SizedBox(height: 2),
                        Text('ENTERPRISE FLEET', style: GoogleFonts.plusJakartaSans(
                          fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 3, color: AppColors.primary)),
                        const SizedBox(height: 24),

                        // Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.slate200.withOpacity(0.5)),
                          ),
                          child: Row(children: [
                            Expanded(child: _toggleBtn('PARENT TERMINAL', true)),
                            const SizedBox(width: 4),
                            Expanded(child: _toggleBtn('ADMIN TERMINAL', false)),
                          ]),
                        ),
                        const SizedBox(height: 28),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(children: [
                            TextFormField(
                              controller: _identifierCtrl,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.slate800),
                              decoration: _isParentMode
                                  ? AppTheme.inputDecoration('Admission No / Email', icon: Icons.badge_outlined)
                                  : AppTheme.adminInputDecoration('Email / Phone', icon: Icons.email_outlined),
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.slate800),
                              decoration: (_isParentMode
                                  ? AppTheme.inputDecoration('Password', icon: Icons.lock_outlined)
                                  : AppTheme.adminInputDecoration('Password', icon: Icons.lock_outlined))
                                .copyWith(suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppColors.slate400, size: 20),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                )),
                              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                child: Text('FORGOT PASSWORD?', style: AppTheme.labelSmall.copyWith(color: AppColors.primary)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: AppTheme.primaryButtonShadow(_isParentMode ? 0.2 : 0.15),
                                ),
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _handleLogin,
                                  style: _isParentMode ? AppTheme.primaryButton : AppTheme.darkButton,
                                  child: auth.isLoading
                                      ? const SizedBox(height: 18, width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text(_isParentMode ? 'ACCESS PORTAL' : 'ACCESS ADMIN',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
                                ),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('NEW USER? ', style: AppTheme.labelSmall.copyWith(color: AppColors.slate400)),
                          GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => RegisterScreen(isParent: _isParentMode))),
                            child: Text('REGISTER ACCOUNT', style: AppTheme.labelSmall.copyWith(color: AppColors.primary)),
                          ),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool isParent) {
    final selected = _isParentMode == isParent;
    return GestureDetector(
      onTap: () => setState(() => _isParentMode = isParent),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? (isParent ? AppColors.primary : AppColors.slate900) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? [BoxShadow(
            color: (isParent ? AppColors.primary : AppColors.slate900).withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          )] : null,
        ),
        child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2,
          color: selected ? Colors.white : AppColors.slate400,
        ))),
      ),
    );
  }
}
