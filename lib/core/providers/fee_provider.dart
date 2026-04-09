import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/monthly_due_model.dart';
import '../../utils/fee_calculator.dart';

class FeeProvider extends ChangeNotifier {
  List<MonthlyDue> _dues = [];
  List<MonthlyDue> _defaulters = [];
  bool _isLoading = false;
  String? _error;

  List<MonthlyDue> get dues => _dues;
  List<MonthlyDue> get defaulters => _defaulters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabase = Supabase.instance.client;

  Future<void> fetchDues() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('monthly_dues')
          .select('*, students(full_name, admission_number, status)')
          .order('year', ascending: false)
          .order('month', ascending: false);

      _dues = (res as List)
          .where((e) => e['students'] != null && (e['students']['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE')
          .map((e) {
        final due = MonthlyDue.fromMap(e);
        if (!due.isPaid) {
          final ledger = FeeCalculator.calculateCurrentLedger(due);
          return MonthlyDue(
            id: due.id,
            studentId: due.studentId,
            studentName: due.studentName,
            admissionNumber: due.admissionNumber,
            month: due.month,
            year: due.year,
            amount: due.amount,
            lateFee: ledger.lateFee,
            discount: due.discount,
            finePerDay: due.finePerDay,
            fineAfterDays: due.fineAfterDays,
            dueDate: due.dueDate,
            lastDate: due.lastDate,
            status: due.status,
            paidAt: due.paidAt,
            transactionId: due.transactionId,
            createdAt: due.createdAt,
          );
        }
        return due;
      }).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchParentDues(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get parent's student IDs
      final students = await _supabase
          .from('students')
          .select('id')
          .eq('parent_id', parentId);

      final studentIds = (students as List).map((s) => s['id'] as String).toList();
      if (studentIds.isEmpty) {
        _dues = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final res = await _supabase
          .from('monthly_dues')
          .select('*, students(full_name, admission_number)')
          .inFilter('student_id', studentIds)
          .order('year', ascending: false)
          .order('month', ascending: false);

      _dues = (res as List).map((e) {
        final due = MonthlyDue.fromMap(e);
        if (!due.isPaid) {
          final ledger = FeeCalculator.calculateCurrentLedger(due);
          return MonthlyDue(
            id: due.id,
            studentId: due.studentId,
            studentName: due.studentName,
            admissionNumber: due.admissionNumber,
            month: due.month,
            year: due.year,
            amount: due.amount,
            lateFee: ledger.lateFee,
            discount: due.discount,
            finePerDay: due.finePerDay,
            fineAfterDays: due.fineAfterDays,
            dueDate: due.dueDate,
            lastDate: due.lastDate,
            status: due.status,
            paidAt: due.paidAt,
            transactionId: due.transactionId,
            createdAt: due.createdAt,
          );
        }
        return due;
      }).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDefaulters() async {
    try {
      final now = DateTime.now();
      final res = await _supabase
          .from('monthly_dues')
          .select('*, students(full_name, admission_number)')
          .neq('status', 'PAID')
          .lt('year', now.year)
          .order('year')
          .order('month');

      // Also get current year past months
      final res2 = await _supabase
          .from('monthly_dues')
          .select('*, students(full_name, admission_number)')
          .neq('status', 'PAID')
          .eq('year', now.year)
          .lt('month', now.month)
          .order('month');

      final all = [...(res as List), ...(res2 as List)];
      _defaulters = all.map((e) => MonthlyDue.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> createFee(Map<String, dynamic> data) async {
    try {
      data['status'] = 'PENDING';
      await _supabase.from('monthly_dues').insert(data);
      await fetchDues();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createFeesForYear({
    required String studentId,
    required double amount,
    required int year,
    required int startMonth,
    required int endMonth,
    required int dueDay,
    double finePerDay = 50,
    int fineAfterDays = 5,
  }) async {
    try {
      int created = 0;
      for (int m = startMonth; m <= endMonth; m++) {
        final dueDate = DateTime(year, m, dueDay);
        final lastDate = DateTime(year, m, dueDay + fineAfterDays + 10);
        try {
          await _supabase.from('monthly_dues').insert({
            'student_id': studentId,
            'month': m,
            'year': year,
            'amount': amount,
            'due_date': dueDate.toIso8601String().split('T')[0],
            'last_date': lastDate.toIso8601String().split('T')[0],
            'fine_per_day': finePerDay,
            'fine_after_days': fineAfterDays,
            'status': 'PENDING',
          });
          created++;
        } catch (_) {
          // Skip duplicates (unique constraint)
        }
      }
      await fetchDues();
      return created > 0;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment(String dueId, {
    required String transactionId,
    String paymentMethod = 'ONLINE',
  }) async {
    try {
      await _supabase.from('monthly_dues').update({
        'status': 'PAID',
        'paid_at': DateTime.now().toIso8601String(),
        'transaction_id': transactionId,
      }).eq('id', dueId);

      // Create receipt
      final receiptNo = 'RCPT-${DateTime.now().millisecondsSinceEpoch}-${dueId.substring(0, 4)}';
      final due = _dues.firstWhere((d) => d.id == dueId, orElse: () => _dues.first);

      await _supabase.from('receipts').insert({
        'due_id': dueId,
        'receipt_no': receiptNo,
        'amount_paid': due.totalDue,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
      });

      await fetchDues();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> waiveLateFee(String dueId) async {
    try {
      await _supabase.from('monthly_dues').update({'late_fee': 0}).eq('id', dueId);
      await fetchDues();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFee(String dueId) async {
    try {
      await _supabase.from('monthly_dues').delete().eq('id', dueId);
      await fetchDues();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
