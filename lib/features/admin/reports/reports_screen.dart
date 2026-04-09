import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fees = context.watch<FeeProvider>();
    final students = context.watch<StudentProvider>();

    final paid = fees.dues.where((d) => d.isPaid).toList();
    final unpaid = fees.dues.where((d) => !d.isPaid).toList();
    final totalRevenue = paid.fold<double>(0, (s, d) => s + d.totalDue);
    final totalOutstanding = unpaid.fold<double>(0, (s, d) => s + d.totalDue);
    final collectionRate = fees.dues.isEmpty ? 0.0 : (paid.length / fees.dues.length) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary Cards
        Row(children: [
          Expanded(child: _summaryCard('Total Revenue', Formatters.currency(totalRevenue), AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Outstanding', Formatters.currency(totalOutstanding), AppColors.error)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _summaryCard('Collection Rate', '${collectionRate.toStringAsFixed(1)}%', AppColors.info)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard('Total Students', '${students.activeStudents.length}', AppColors.primary)),
        ]),
        const SizedBox(height: 24),

        // Payment Distribution Pie
        const Text('Payment Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Expanded(
              child: PieChart(PieChartData(
                sections: [
                  PieChartSectionData(value: paid.length.toDouble(), color: AppColors.paid,
                      title: '${paid.length}', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  PieChartSectionData(value: unpaid.length.toDouble(), color: AppColors.overdue,
                      title: '${unpaid.length}', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              )),
            ),
            const SizedBox(width: 16),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _legend('Paid', AppColors.paid),
              const SizedBox(height: 8),
              _legend('Unpaid', AppColors.overdue),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        // Top Defaulters
        const Text('Top Defaulters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...fees.defaulters.take(10).map((d) => Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            title: Text(d.studentName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${d.monthLabel} • ${d.admissionNumber ?? ""}', style: const TextStyle(fontSize: 12)),
            trailing: Text(Formatters.currencyFull(d.totalDue),
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        )),
      ]),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: color.withOpacity(0.8))),
      ]),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13)),
    ]);
  }
}
