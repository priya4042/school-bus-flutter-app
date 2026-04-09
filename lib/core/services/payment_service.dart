import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../models/monthly_due_model.dart';

/// Payment steps matching React usePayments hook
enum PaymentStep { select, processing, upiConfirm, success }

/// Payment state matching React PaymentState
class PaymentState {
  final bool isOpen;
  final String? dueId;
  final List<String> dueIds;
  final double amount;
  final String studentName;
  final Map<String, dynamic>? studentMeta;
  final PaymentStep step;
  final String? transactionId;
  final bool loading;
  final String? error;

  PaymentState({
    this.isOpen = false,
    this.dueId,
    this.dueIds = const [],
    this.amount = 0,
    this.studentName = '',
    this.studentMeta,
    this.step = PaymentStep.select,
    this.transactionId,
    this.loading = false,
    this.error,
  });

  PaymentState copyWith({
    bool? isOpen,
    String? dueId,
    List<String>? dueIds,
    double? amount,
    String? studentName,
    Map<String, dynamic>? studentMeta,
    PaymentStep? step,
    String? transactionId,
    bool? loading,
    String? error,
  }) {
    return PaymentState(
      isOpen: isOpen ?? this.isOpen,
      dueId: dueId ?? this.dueId,
      dueIds: dueIds ?? this.dueIds,
      amount: amount ?? this.amount,
      studentName: studentName ?? this.studentName,
      studentMeta: studentMeta ?? this.studentMeta,
      step: step ?? this.step,
      transactionId: transactionId ?? this.transactionId,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class PaymentService {
  static final _supabase = Supabase.instance.client;

  /// Payment API base URLs (matching React getPaymentApiBases)
  static List<String> get _apiBaseUrls => [
    AppConstants.paymentApiBaseUrl,
    AppConstants.appUrl,
    AppConstants.apiBaseUrl,
  ].where((u) => u.isNotEmpty).toSet().toList();

  /// Get auth token
  static Future<String?> _getToken() async {
    final session = _supabase.auth.currentSession;
    return session?.accessToken;
  }

  // ===== METHOD 1: PayU Bolt Checkout =====

  /// Step 1: Create PayU hash via /api/v1/payments/createOrder
  static Future<Map<String, dynamic>?> createPayUHash({
    required double amount,
    required String dueId,
    required List<String> dueIds,
    required String studentId,
    required int month,
    required String studentName,
    required String email,
    String phone = '',
  }) async {
    final token = await _getToken();

    for (final baseUrl in _apiBaseUrls) {
      try {
        final url = '$baseUrl/api/v1/payments/createOrder';
        final body = {
          'amount': amount,
          'dueId': dueId,
          'due_id': dueId,
          'due_ids': dueIds,
          'studentId': studentId,
          'month': month,
          'studentName': studentName,
          'email': email,
          'phone': phone,
        };

        final res = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['hash'] != null) return data;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Step 2: Verify PayU payment via /api/v1/payments/verifyPayment
  static Future<Map<String, dynamic>?> verifyPayUPayment({
    required Map<String, dynamic> payuResponse,
    required String dueId,
    required List<String> dueIds,
  }) async {
    final token = await _getToken();

    for (final baseUrl in _apiBaseUrls) {
      try {
        final url = '$baseUrl/api/v1/payments/verifyPayment';
        final body = {
          ...payuResponse,
          'dueId': dueId,
          'due_id': dueId,
          'due_ids': dueIds,
        };

        final res = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          return jsonDecode(res.body);
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // ===== METHOD 2: UPI Intent =====

  /// Build UPI intent URL and launch
  static Future<String?> initiateUpiIntent({
    required double amount,
    required String studentName,
    required String upiId,
  }) async {
    if (upiId.isEmpty) return null;

    final txnRef = 'BUSWAY${DateTime.now().millisecondsSinceEpoch}';
    final note = 'Bus Fee - $studentName';

    final upiUrl = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': 'School Bus WayPro',
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
        'tn': note,
        'tr': txnRef,
      },
    );

    try {
      if (await canLaunchUrl(upiUrl)) {
        await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
        return txnRef;
      }
    } catch (_) {}

    // Fallback: try as string URL
    try {
      final fallbackUrl = 'upi://pay?pa=${Uri.encodeComponent(upiId)}'
          '&pn=${Uri.encodeComponent("School Bus WayPro")}'
          '&am=${amount.toStringAsFixed(2)}'
          '&cu=INR'
          '&tn=${Uri.encodeComponent(note)}'
          '&tr=$txnRef';
      await launchUrl(Uri.parse(fallbackUrl), mode: LaunchMode.externalApplication);
      return txnRef;
    } catch (_) {
      return null;
    }
  }

  // ===== METHOD 3: Record UPI/Manual Payment (shared by Method 2 & 3) =====

  /// Record manual UPI payment (same as React confirmUpiPayment)
  static Future<bool> confirmUpiPayment({
    required String upiRefId,
    required List<String> dueIds,
    required double amount,
    required String studentName,
  }) async {
    final now = DateTime.now().toIso8601String();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      // 1. Update all dues as PAID
      for (final dueId in dueIds) {
        await _supabase.from('monthly_dues').update({
          'status': 'PAID',
          'paid_at': now,
          'transaction_id': upiRefId,
        }).eq('id', dueId);
      }

      // 2. Create receipts
      for (int i = 0; i < dueIds.length; i++) {
        final existing = await _supabase
            .from('receipts')
            .select('id')
            .eq('due_id', dueIds[i])
            .maybeSingle();

        if (existing == null) {
          final random = DateTime.now().microsecond % 1000;
          await _supabase.from('receipts').insert({
            'due_id': dueIds[i],
            'receipt_no': 'UPI-$timestamp-$i-$random',
            'amount_paid': amount,
            'payment_method': 'UPI',
            'transaction_id': upiRefId,
            'created_at': now,
          });
        }
      }

      // 3. Notify admin
      final admins = await _supabase
          .from('profiles')
          .select('id')
          .or('role.eq.ADMIN,role.eq.SUPER_ADMIN')
          .limit(1);

      if (admins is List && admins.isNotEmpty) {
        await _supabase.from('notifications').insert({
          'user_id': admins[0]['id'],
          'title': 'UPI Payment Received',
          'message': '$studentName paid ₹${amount.toStringAsFixed(0)} via UPI. Ref: $upiRefId. Please verify in your bank app.',
          'type': 'SUCCESS',
          'is_read': false,
        });
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== RECORD PAYU PAYMENT LOCALLY (after server verification) =====

  /// Persist payment records locally after server-side verification succeeds
  static Future<bool> persistPaymentRecords({
    required List<String> dueIds,
    required String transactionId,
    required double amount,
    required String studentName,
    String paymentMethod = 'ONLINE',
  }) async {
    final now = DateTime.now().toIso8601String();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      for (int i = 0; i < dueIds.length; i++) {
        // Update due
        await _supabase.from('monthly_dues').update({
          'status': 'PAID',
          'paid_at': now,
          'transaction_id': transactionId,
        }).eq('id', dueIds[i]);

        // Create receipt
        final existing = await _supabase
            .from('receipts')
            .select('id')
            .eq('due_id', dueIds[i])
            .maybeSingle();

        if (existing == null) {
          final random = DateTime.now().microsecond % 1000;
          final suffix = dueIds[i].length >= 4 ? dueIds[i].substring(0, 4) : dueIds[i];
          await _supabase.from('receipts').insert({
            'due_id': dueIds[i],
            'receipt_no': 'RCPT-$timestamp-$i-$suffix-$random',
            'amount_paid': amount,
            'payment_method': paymentMethod,
            'transaction_id': transactionId,
            'created_at': now,
          });
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== FEE SETTINGS (QR URL + UPI ID) =====

  /// Load admin UPI settings from fee settings API
  static Future<Map<String, String>> loadUpiSettings() async {
    try {
      for (final baseUrl in _apiBaseUrls) {
        try {
          final res = await http.get(
            Uri.parse('$baseUrl/api/settings/fees'),
          ).timeout(const Duration(seconds: 5));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            return {
              'adminUpiId': data['adminUpiId']?.toString() ?? '',
              'adminPaymentQrUrl': data['adminPaymentQrUrl']?.toString() ?? '',
            };
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}
    return {'adminUpiId': '', 'adminPaymentQrUrl': ''};
  }

  // ===== HEALTH CHECK =====

  /// Check payment gateway health
  static Future<bool> checkHealth() async {
    for (final baseUrl in _apiBaseUrls) {
      try {
        final res = await http.get(
          Uri.parse('$baseUrl/api/v1/payments/health'),
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          return data['ok'] == true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}
