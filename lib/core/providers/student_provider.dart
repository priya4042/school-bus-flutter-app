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
          .select('*, routes(*), buses(*), profiles(*)')
          .order('created_at', ascending: false);

      _students = (res as List).map((e) => Student.fromMap(e)).toList();
      debugPrint('[StudentProvider] Admin fetched ${_students.length} students');
    } catch (e) {
      _error = e.toString();
      debugPrint('[StudentProvider] Error fetching students: $e');
      // Fallback without joins
      try {
        final res = await _supabase.from('students').select();
        _students = (res as List).map((e) => Student.fromMap(e)).toList();
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchParentStudents(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch students linked to this parent
      final res = await _supabase
          .from('students')
          .select()
          .eq('parent_id', parentId)
          .order('full_name', ascending: true);

      final basicStudents = (res as List).cast<Map<String, dynamic>>();
      debugPrint('[StudentProvider] Fetched ${basicStudents.length} students for parent $parentId');

      // Now fetch the routes and buses for these students separately
      final List<Student> enriched = [];
      for (final s in basicStudents) {
        Map<String, dynamic>? routeData;
        Map<String, dynamic>? busData;

        // Fetch route if assigned
        if (s['route_id'] != null) {
          try {
            routeData = await _supabase
                .from('routes')
                .select()
                .eq('id', s['route_id'])
                .maybeSingle();
          } catch (_) {}
        }

        // Fetch bus if assigned
        if (s['bus_id'] != null) {
          try {
            busData = await _supabase
                .from('buses')
                .select()
                .eq('id', s['bus_id'])
                .maybeSingle();
          } catch (_) {}
        }

        // Merge into student map for fromMap
        final merged = Map<String, dynamic>.from(s);
        if (routeData != null) merged['routes'] = routeData;
        if (busData != null) merged['buses'] = busData;

        enriched.add(Student.fromMap(merged));
      }

      _students = enriched;
      debugPrint('[StudentProvider] Enriched ${_students.length} students with routes/buses');
    } catch (e) {
      _error = e.toString();
      debugPrint('[StudentProvider] Error fetching parent students: $e');
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
