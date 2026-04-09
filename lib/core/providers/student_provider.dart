import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentProvider extends ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Student> get activeStudents =>
      _students.where((s) => s.isActive).toList();

  final _supabase = Supabase.instance.client;

  Future<void> fetchStudents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('students')
          .select('*, routes(route_name), buses(bus_number, vehicle_number), profiles(full_name, phone_number)')
          .order('created_at', ascending: false);

      _students = (res as List).map((e) => Student.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchParentStudents(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('students')
          .select('*, routes(route_name, code, start_point, end_point), buses(bus_number, vehicle_number)')
          .eq('parent_id', parentId)
          .order('full_name');

      _students = (res as List).map((e) => Student.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addStudent(Map<String, dynamic> data) async {
    try {
      // Resolve parent by phone if provided
      if (data['parent_phone'] != null && data['parent_id'] == null) {
        final phone = data['parent_phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
        final last10 = phone.length > 10 ? phone.substring(phone.length - 10) : phone;
        final profile = await _supabase
            .from('profiles')
            .select('id')
            .ilike('phone_number', '%$last10')
            .maybeSingle();
        if (profile != null) {
          data['parent_id'] = profile['id'];
        }
      }
      data.remove('parent_phone');
      data.remove('parent_name');

      await _supabase.from('students').insert(data);
      await fetchStudents();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent(String id, Map<String, dynamic> data) async {
    try {
      data.remove('parent_phone');
      data.remove('parent_name');
      data.remove('routes');
      data.remove('buses');
      data.remove('profiles');

      await _supabase.from('students').update(data).eq('id', id);
      await fetchStudents();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String id, {String reason = 'Deleted by admin'}) async {
    try {
      await _supabase.rpc('archive_and_delete_student', params: {
        'p_student_id': id,
        'p_deleted_reason': reason,
      });
      await fetchStudents();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
