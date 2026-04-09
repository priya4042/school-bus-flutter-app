import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/monthly_due_model.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class ParentReceiptsScreen extends StatefulWidget {
  const ParentReceiptsScreen({super.key});

  @override
  State<ParentReceiptsScreen> createState() => _ParentReceiptsScreenState();
}

class _ParentReceiptsScreenState extends State<ParentReceiptsScreen> {
  List<Map<String, dynamic>> _receipts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;

    try {
      final students = await Supabase.instance.client
          .from('students')
          .select('id')
          .eq('parent_id', auth.user!.id);
      final ids = (students as List).map((s) => s['id'] as String).toList();

      if (ids.isNotEmpty) {
        final dues = await Supabase.instance.client
            .from('monthly_dues')
            .select('*, students(full_name, admission_number)')
            .inFilter('student_id', ids)
            .eq('status', 'PAID')
            .order('paid_at', ascending: false);

        final receipts = await Supabase.instance.client
            .from('receipts')
            .select('*')
            .inFilter('due_id', (dues as List).map((d) => d['id']).toList());

        _receipts = (dues).map((d) {
          final r = (receipts as List).firstWhere(
              (r) => r['due_id'] == d['id'],
              orElse: () => <String, dynamic>{});
          return {...d, 'receipt': r};
        }).toList();
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_receipts.isEmpty) {
      return const EmptyState(
          icon: Icons.receipt_outlined, title: 'No receipts yet',
          subtitle: 'Receipts appear after payments');
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _receipts.length,
        itemBuilder: (_, i) {
          final data = _receipts[i];
          final due = MonthlyDue.fromMap(data);
          final receipt = data['receipt'] as Map<String, dynamic>?;
          final receiptNo = receipt?['receipt_no'] ?? 'N/A';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, color: AppColors.success),
              ),
              title: Text(due.fullMonthLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(due.studentName ?? '', style: const TextStyle(fontSize: 12)),
                  Text(receiptNo, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Formatters.currencyFull(due.totalDue),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(due.paidAt != null ? Formatters.dateShort(due.paidAt!) : '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              isThreeLine: true,
              onTap: () => ReceiptService.generateAndShareReceipt(
                due: due,
                studentName: due.studentName,
                admissionNumber: due.admissionNumber,
                receiptNo: receiptNo != 'N/A' ? receiptNo : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
