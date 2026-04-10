import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/models/monthly_due_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String _filter = 'ALL';
  String _search = '';

  @override
  void initState() {
    super.initState();
    context.read<FeeProvider>().fetchDues();
  }

  @override
  Widget build(BuildContext context) {
    final feeProv = context.watch<FeeProvider>();
    final allDues = feeProv.dues;

    final paid = allDues.where((d) => d.isPaid).toList();
    final overdue = allDues.where((d) => d.isOverdue && !d.isPaid).toList();
    final pending = allDues.where((d) => d.isPending && !d.isOverdue).toList();
    final totalRevenue = paid.fold<double>(0, (s, d) => s + d.totalDue);

    var filtered = allDues.toList();
    if (_filter == 'PAID') filtered = paid;
    if (_filter == 'OVERDUE') filtered = overdue;
    if (_filter == 'PENDING') filtered = pending;

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where((d) =>
          (d.studentName?.toLowerCase().contains(q) ?? false) ||
          (d.admissionNumber?.toLowerCase().contains(q) ?? false)).toList();
    }

    return RefreshIndicator(
      onRefresh: () => feeProv.fetchDues(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                _miniStat('Revenue', Formatters.currency(totalRevenue), AppColors.success),
                _miniStat('Paid', '${paid.length}', AppColors.paid),
                _miniStat('Overdue', '${overdue.length}', AppColors.overdue),
              ],
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('All', 'ALL'),
                _filterChip('Paid', 'PAID'),
                _filterChip('Overdue', 'OVERDUE'),
                _filterChip('Pending', 'PENDING'),
              ]),
            ),
            const SizedBox(height: 16),

            // Payment List
            if (feeProv.isLoading)
              const MiniLoader()
            else if (filtered.isEmpty)
              const EmptyState(icon: Icons.payment_outlined, title: 'No payments found')
            else
              ...filtered.map((d) => _paymentCard(d)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
      ]),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary.withOpacity(0.15),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  Widget _paymentCard(MonthlyDue d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(d.admissionNumber ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ])),
            StatusBadge.fromStatus(d.isPaid ? 'PAID' : d.isOverdue ? 'OVERDUE' : 'PENDING'),
          ]),
          const Divider(height: 16),
          Row(children: [
            _detail('Period', d.monthLabel),
            _detail('Base', Formatters.currencyFull(d.amount)),
            if (d.lateFee > 0) _detail('Late', Formatters.currencyFull(d.lateFee), color: AppColors.error),
            _detail('Total', Formatters.currencyFull(d.totalDue), bold: true),
          ]),
          if (d.isPaid && d.paidAt != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text('Paid ${Formatters.dateTime(d.paidAt!)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.success)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _detail(String label, String value, {Color? color, bool bold = false}) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppColors.textPrimary)),
      ]),
    );
  }
}
