import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/models/monthly_due_model.dart';
import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../utils/fee_calculator.dart';
import '../../shared/widgets/stat_card.dart';

class FeeHistoryScreen extends StatefulWidget {
  const FeeHistoryScreen({super.key});

  @override
  State<FeeHistoryScreen> createState() => _FeeHistoryScreenState();
}

class _FeeHistoryScreenState extends State<FeeHistoryScreen> {
  String? _selectedStudentId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    await context.read<FeeProvider>().fetchParentDues(auth.user!.id);
  }

  Future<void> _handlePay(MonthlyDue due) async {
    final fees = context.read<FeeProvider>();
    final bundle = FeeCalculator.buildPaymentBundle(due, fees.dues);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PaymentSheet(bundle: bundle),
    );

    if (confirmed == true) {
      // Simulate payment (in production: integrate PayU/UPI)
      final txnId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      for (final id in bundle.dueIds) {
        await fees.recordPayment(id, transactionId: txnId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final fees = context.watch<FeeProvider>();

    var dues = fees.dues.toList();
    if (_selectedStudentId != null) {
      dues = dues.where((d) => d.studentId == _selectedStudentId).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      dues = dues.where((d) =>
          d.monthLabel.toLowerCase().contains(q) ||
          (d.studentName?.toLowerCase().contains(q) ?? false)).toList();
    }

    final paid = dues.where((d) => d.isPaid).toList();
    final unpaid = dues.where((d) => !d.isPaid).toList();
    final totalCleared = paid.fold<double>(0, (s, d) => s + d.totalDue);
    final outstanding = unpaid.fold<double>(0, (s, d) => s + d.totalDue);

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stats
          Row(children: [
            Expanded(child: _stat('Cleared', Formatters.currency(totalCleared), AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _stat('Outstanding', Formatters.currency(outstanding), AppColors.error)),
            const SizedBox(width: 8),
            Expanded(child: _stat('Overdue', '${unpaid.where((d) => d.isOverdue).length}', AppColors.warning)),
          ]),
          const SizedBox(height: 16),

          // Filters
          if (students.length > 1)
            DropdownButtonFormField<String>(
              value: _selectedStudentId,
              decoration: const InputDecoration(labelText: 'Filter by Student', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Students')),
                ...students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))),
              ],
              onChanged: (v) => setState(() => _selectedStudentId = v),
            ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search), isDense: true),
          ),
          const SizedBox(height: 16),

          // Fee List
          if (fees.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (dues.isEmpty)
            const EmptyState(icon: Icons.receipt_long_outlined, title: 'No fees found')
          else
            ...dues.map((d) => _feeCard(d, fees.dues)),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
      ]),
    );
  }

  Widget _feeCard(MonthlyDue d, List<MonthlyDue> allDues) {
    final isPayable = d.isPaid ? false : FeeCalculator.isMonthPayable(d, allDues);
    final isLocked = !d.isPaid && !isPayable;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.fullMonthLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (d.studentName != null)
                Text(d.studentName!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            StatusBadge.fromStatus(d.isPaid ? 'PAID' : d.isOverdue ? 'OVERDUE' : 'PENDING'),
          ]),
          const Divider(height: 16),
          Row(children: [
            _info('Base', Formatters.currencyFull(d.amount)),
            if (d.lateFee > 0) _info('Late', Formatters.currencyFull(d.lateFee), color: AppColors.error),
            _info('Total', Formatters.currencyFull(d.totalDue), bold: true),
          ]),
          if (!d.isPaid) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (isLocked)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text('Pay previous months first',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handlePay(d),
                    child: const Text('Pay Now'),
                  ),
                ),
            ]),
          ] else ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.check_circle, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('Paid ${d.paidAt != null ? Formatters.date(d.paidAt!) : ""}',
                  style: const TextStyle(fontSize: 12, color: AppColors.success)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ReceiptService.generateAndShareReceipt(
                  due: d, studentName: d.studentName, admissionNumber: d.admissionNumber),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Receipt', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _info(String label, String value, {Color? color, bool bold = false}) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? AppColors.textPrimary)),
    ]));
  }
}

class _PaymentSheet extends StatelessWidget {
  final PaymentBundle bundle;
  const _PaymentSheet({required this.bundle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(
          color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        const Text('Payment Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),

        // Breakdown
        ...bundle.items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item.due.monthLabel),
            Text(Formatters.currencyFull(item.total)),
          ]),
        )),
        const Divider(height: 20),

        if (bundle.totalLateFee > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Late Fees', style: TextStyle(color: AppColors.error)),
              Text(Formatters.currencyFull(bundle.totalLateFee),
                  style: const TextStyle(color: AppColors.error)),
            ]),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(Formatters.currencyFull(bundle.amount),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
        ),

        if (bundle.explanation.isNotEmpty)
          Text(bundle.explanation, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Pay ${Formatters.currencyFull(bundle.amount)}'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
      ]),
    );
  }
}
