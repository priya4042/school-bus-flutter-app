import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_model.dart';

class AttendanceProvider extends ChangeNotifier {
  List<Attendance> _records = [];
  bool _isLoading = false;
  String? _error;

  List<Attendance> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabase = Supabase.instance.client;

  Future<void> fetchAttendance({String? date, String? type}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var query = _supabase
          .from('attendance')
          .select('*, students(full_name, admission_number)')
          .order('created_at', ascending: false);

      final res = await query;
      _records = (res as List).map((e) => Attendance.fromMap(e)).toList();

      if (date != null) {
        _records = _records.where((r) =>
            r.createdAt.toIso8601String().split('T')[0] == date).toList();
      }
      if (type != null && type != 'ALL') {
        _records = _records.where((r) => r.type == type).toList();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStudentAttendance(String studentId, {int limit = 90}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('attendance')
          .select('*')
          .eq('student_id', studentId)
          .order('created_at', ascending: false)
          .limit(limit);

      _records = (res as List).map((e) => Attendance.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAttendance({
    required String studentId,
    required String type,
    required String status,
    String? busId,
  }) async {
    try {
      await _supabase.from('attendance').upsert({
        'student_id': studentId,
        'type': type,
        'status': status,
        'bus_id': busId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Stats helpers
  int get totalPresent => _records.where((r) => r.isPresent).length;
  int get totalAbsent => _records.where((r) => !r.isPresent).length;
  int get pickupPresent => _records.where((r) => r.isPickup && r.isPresent).length;
  int get dropPresent => _records.where((r) => !r.isPickup && r.isPresent).length;

  double get attendanceRate {
    if (_records.isEmpty) return 0;
    return (totalPresent / _records.length) * 100;
  }
}
