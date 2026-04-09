import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  int _selectedChild = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    await context.read<FeeProvider>().fetchParentDues(auth.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final students = context.watch<StudentProvider>().students;
    final fees = context.watch<FeeProvider>();

    if (students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: EmptyState(icon: Icons.child_care, title: 'No children linked',
              subtitle: 'Contact admin to link your child\'s admission'),
        ),
      );
    }

    final child = students[_selectedChild.clamp(0, students.length - 1)];
    final childDues = fees.dues.where((d) => d.studentId == child.id).toList();
    final unpaid = childDues.where((d) => !d.isPaid).toList();
    final totalDue = unpaid.fold<double>(0, (s, d) => s + d.totalDue);
    final nextDue = unpaid.isNotEmpty ? unpaid.last : null;
    final paidCount = childDues.where((d) => d.isPaid).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Child selector
          if (students.length > 1) ...[
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s = students[i];
                  final selected = i == _selectedChild;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.fullName),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedChild = i),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Student Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Text(child.fullName.isNotEmpty ? child.fullName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(child.fullName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('${child.admissionNumber} • ${child.displayGrade}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _chipInfo(Icons.route, child.routeName ?? 'No route'),
                const SizedBox(width: 12),
                _chipInfo(Icons.directions_bus, child.busNumber ?? 'No bus'),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              StatCard(
                title: 'Total Due',
                value: totalDue > 0 ? Formatters.currencyFull(totalDue) : 'All Clear',
                icon: totalDue > 0 ? Icons.warning_amber : Icons.check_circle,
                color: totalDue > 0 ? AppColors.error : AppColors.success,
                onTap: () => nav.setTab('fees'),
              ),
              StatCard(
                title: 'Months Paid',
                value: '$paidCount',
                icon: Icons.receipt_long,
                color: AppColors.info,
                onTap: () => nav.setTab('receipts'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Next Due
          if (nextDue != null) ...[
            const Text('Next Due', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: nextDue.isOverdue ? AppColors.error.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today,
                        color: nextDue.isOverdue ? AppColors.error : AppColors.warning),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nextDue.fullMonthLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Due: ${Formatters.date(nextDue.dueDate)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(Formatters.currencyFull(nextDue.totalDue),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    StatusBadge.fromStatus(nextDue.isOverdue ? 'OVERDUE' : 'PENDING'),
                  ]),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Quick Actions
          const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: [
              _quickAction(Icons.payment, 'Pay Fees', () => nav.setTab('fees')),
              _quickAction(Icons.gps_fixed, 'Track Bus', () => nav.setTab('parent_tracking')),
              _quickAction(Icons.fact_check, 'Attendance', () => nav.setTab('attendance_history')),
              _quickAction(Icons.support_agent, 'Support', () => nav.setTab('support')),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _chipInfo(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
