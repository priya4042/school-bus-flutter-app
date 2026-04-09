import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AdminProvider extends ChangeNotifier {
  List<AppUser> _admins = [];
  bool _isLoading = false;
  String? _error;

  List<AppUser> get admins => _admins;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabase = Supabase.instance.client;

  Future<void> fetchAdmins() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('profiles')
          .select()
          .or('role.eq.ADMIN,role.eq.SUPER_ADMIN')
          .order('full_name');

      _admins = (res as List).map((e) => AppUser.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAdmin({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        await _supabase.from('profiles').upsert({
          'id': res.user!.id,
          'email': email,
          'full_name': fullName,
          'role': role,
        });
        await fetchAdmins();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
