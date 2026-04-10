import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/models/monthly_due_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../../utils/fee_calculator.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/stylish_loader.dart';

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
    final studentProv = context.watch<StudentProvider>();
    final students = studentProv.students;
    final fees = context.watch<FeeProvider>();
    final t = context.watch<LocaleProvider>().t;

    // Show loader while fetching initial data
    if (studentProv.isLoading || fees.isLoading) {
      return Center(child: StylishLoader(label: t('loading'), size: 64));
    }

    if (students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: EmptyState(
              icon: Icons.child_care_rounded,
              title: t('no_students'),
              subtitle: t('link_child'),
            ),
          ),
        ),
      );
    }

    final child = students[_selectedChild.clamp(0, students.length - 1)];
    final childDues = fees.dues.where((d) => d.studentId == child.id).toList();
    final unpaid = childDues.where((d) => !d.isPaid).toList();
    final totalDue = unpaid.fold<double>(0, (s, d) => s + d.totalDue);
    final paidDues = childDues.where((d) => d.isPaid).toList();

    // Build fee manifest - sorted chronologically
    final sortedDues = List<MonthlyDue>.from(childDues)
      ..sort((a, b) {
        final y = a.year.compareTo(b.year);
        return y != 0 ? y : a.month.compareTo(b.month);
      });

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ===== HERO CARD =====
          // bg-white p-6 md:p-10 rounded-3xl border border-slate-200 shadow-premium
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.slate200),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: Column(children: [
              Row(children: [
                // Icon box: bg-primary/5 text-primary rounded-2xl
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t('family_hub'), style: const TextStyle(fontFamily: 'Inter',
                    fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.slate900)),
                  Text(t('school_bus_mgmt'), style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate500)),
                ])),
              ]),
              const SizedBox(height: 20),
              // Total due display
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t('total_due'), style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 0.3, color: AppColors.slate500)),
                  const SizedBox(height: 4),
                  Text(
                    totalDue > 0 ? Formatters.currencyFull(totalDue) : t('paid'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: totalDue > 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ]),
                if (totalDue > 0)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.primaryButtonShadow(),
                    ),
                    child: ElevatedButton(
                      onPressed: () => nav.setTab('fees'),
                      style: AppTheme.primaryButton,
                      child: Text(t('pay_now'), style: const TextStyle(fontFamily: 'Inter',
                        fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    ),
                  ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ===== CHILD SELECTOR CHIPS =====
          if (students.length > 1) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200.withOpacity(0.5)),
              ),
              child: Row(children: List.generate(students.length, (i) {
                final s = students[i];
                final selected = i == _selectedChild;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _selectedChild = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: selected ? [BoxShadow(
                        color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4),
                      )] : null,
                    ),
                    child: Center(child: Text(
                      s.fullName.split(' ').first.toUpperCase(),
                      style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
                        color: selected ? Colors.white : AppColors.slate400,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                  ),
                ));
              })),
            ),
            const SizedBox(height: 20),
          ],

          // ===== FEE MANIFEST =====
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.slate200),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(bottom: BorderSide(color: AppColors.slate100)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t('fee_history'), style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.3, color: AppColors.slate500)),
                    const SizedBox(height: 4),
                    Text(child.fullName, style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
                      letterSpacing: -0.2, color: AppColors.slate900)),
                  ]),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                  ),
                ]),
              ),

              // Dues list
              if (sortedDues.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(t('no_data'), style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.slate400)),
                )
              else
                ...sortedDues.map((d) {
                  final isPayable = !d.isPaid && FeeCalculator.isMonthPayable(d, childDues);
                  final isLocked = !d.isPaid && !isPayable;

                  return Opacity(
                    opacity: isLocked ? 0.4 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.slate50)),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.fullMonthLabel, style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
                            letterSpacing: -0.2, color: AppColors.slate900)),
                          const SizedBox(height: 4),
                          StatusBadge.fromStatus(
                            d.isPaid ? 'PAID' : isLocked ? 'FUTURE' : d.isOverdue ? 'OVERDUE' : 'PENDING',
                          ),
                          if (!d.isPaid && d.lateFee > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('${t('late_fee')}: ${Formatters.currencyFull(d.lateFee)}',
                                style: const TextStyle(fontFamily: 'Inter',
                                  fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.danger)),
                            ),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(Formatters.currencyFull(d.totalDue), style: const TextStyle(
                            fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700,
                            letterSpacing: -0.5, color: AppColors.slate900)),
                          const SizedBox(height: 6),
                          if (d.isPaid)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(t('paid'), style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                            ])
                          else if (isPayable)
                            GestureDetector(
                              onTap: () => nav.setTab('fees'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: AppTheme.primaryButtonShadow(),
                                ),
                                child: Text(t('pay_now'), style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2, color: Colors.white)),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.lock_rounded, size: 11, color: AppColors.slate400),
                                const SizedBox(width: 4),
                                Text(t('pay_previous'), style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                                  color: AppColors.slate400)),
                              ]),
                            ),
                        ]),
                      ]),
                    ),
                  );
                }),

              // View all link
              GestureDetector(
                onTap: () => nav.setTab('fees'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                  ),
                  child: Center(child: Text('VIEW FULL LEDGER →', style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.primary))),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ===== QUICK ACTIONS =====
          Text('QUICK ACCESS', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _quickAction(Icons.gps_fixed_rounded, 'TRACK', () => nav.setTab('parent_tracking')),
              _quickAction(Icons.fact_check_rounded, 'ATTEND', () => nav.setTab('attendance_history')),
              _quickAction(Icons.receipt_rounded, 'RECEIPTS', () => nav.setTab('receipts')),
              _quickAction(Icons.headset_mic_rounded, 'SUPPORT', () => nav.setTab('support')),
            ],
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.slate100),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontFamily: 'Inter', 
            fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.slate500)),
        ]),
      ),
    );
  }
}
