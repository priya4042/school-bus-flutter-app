import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AppAuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isLoading = true;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isParent => _user?.isParent ?? false;

  final _supabase = Supabase.instance.client;

  AppAuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Wait for Supabase to restore session (with timeout)
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadProfile(session.user.id).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('[Auth] Profile load timed out');
          },
        );
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[Auth] Init error: $e');
    }

    _isLoading = false;
    notifyListeners();

    // Listen for future auth changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        await _loadProfile(data.session!.user.id);
        notifyListeners();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 6));

      if (res != null) {
        _user = AppUser.fromMap(res);
      } else {
        // Fallback: build minimal user from auth session
        final authUser = _supabase.auth.currentUser;
        if (authUser != null) {
          _user = AppUser(
            id: authUser.id,
            email: authUser.email ?? '',
            fullName: authUser.userMetadata?['full_name'] ?? authUser.email ?? 'User',
            role: UserRole.parent,
          );
        }
      }
    } catch (e) {
      debugPrint('[Auth] Failed to load profile: $e');
      // Fallback: build minimal user from auth session
      final authUser = _supabase.auth.currentUser;
      if (authUser != null) {
        _user = AppUser(
          id: authUser.id,
          email: authUser.email ?? '',
          fullName: authUser.email ?? 'User',
          role: UserRole.parent,
        );
      }
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await _loadProfile(res.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Login failed';
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithAdmission(String admissionNumber, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Lookup student by admission number to find parent email
      final student = await _supabase
          .from('students')
          .select('parent_id')
          .eq('admission_number', admissionNumber.toUpperCase())
          .maybeSingle();

      if (student == null) {
        _error = 'Admission number not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profile = await _supabase
          .from('profiles')
          .select('email')
          .eq('id', student['parent_id'])
          .maybeSingle();

      if (profile == null || profile['email'] == null) {
        _error = 'Parent account not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      return await loginWithEmail(profile['email'], password);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithPhone(String phone, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final normalized = phone.replaceAll(RegExp(r'[^0-9]'), '');
      final last10 = normalized.length > 10
          ? normalized.substring(normalized.length - 10)
          : normalized;

      final profile = await _supabase
          .from('profiles')
          .select('email')
          .or('phone_number.ilike.%$last10')
          .maybeSingle();

      if (profile == null || profile['email'] == null) {
        _error = 'Phone number not registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      return await loginWithEmail(profile['email'], password);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? admissionNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final roleStr = role == UserRole.superAdmin
            ? 'SUPER_ADMIN'
            : role == UserRole.admin
                ? 'ADMIN'
                : 'PARENT';

        await _supabase.from('profiles').upsert({
          'id': res.user!.id,
          'email': email,
          'full_name': fullName,
          'phone_number': phone,
          'role': roleStr,
          if (admissionNumber != null) 'admission_number': admissionNumber,
        });

        // Link student if parent registering with admission number
        if (role == UserRole.parent && admissionNumber != null) {
          await _supabase
              .from('students')
              .update({'parent_id': res.user!.id})
              .eq('admission_number', admissionNumber.toUpperCase());
        }

        await _loadProfile(res.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = 'Registration failed';
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return;
    try {
      await _supabase.from('profiles').update(data).eq('id', _user!.id);
      await _loadProfile(_user!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _user = null;
    notifyListeners();
  }
}
