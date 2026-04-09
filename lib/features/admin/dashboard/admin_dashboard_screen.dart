import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/bus_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final studentProv = context.read<StudentProvider>();
    final busProv = context.read<BusProvider>();
    final feeProv = context.read<FeeProvider>();
    final routeProv = context.read<RouteProvider>();

    await Future.wait([
      studentProv.fetchStudents(),
      busProv.fetchBuses(),
      feeProv.fetchDues(),
      routeProv.fetchRoutes(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>();
    final buses = context.watch<BusProvider>();
    final fees = context.watch<FeeProvider>();
    final routes = context.watch<RouteProvider>();
    final nav = context.read<NavigationProvider>();

    final totalStudents = students.activeStudents.length;
    final totalBuses = buses.buses.length;
    final activeBuses = buses.activeBuses.length;
    final totalRoutes = routes.routes.length;

    final paidDues = fees.dues.where((d) => d.isPaid).toList();
    final totalRevenue = paidDues.fold<double>(0, (sum, d) => sum + d.totalDue);
    final overdueDues = fees.dues.where((d) => d.isOverdue && !d.isPaid).length;
    final pendingDues = fees.dues.where((d) => d.isPending).length;

    // Revenue by month (last 6 months)
    final now = DateTime.now();
    final revenueByMonth = <int, double>{};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final month = m.month;
      final year = m.year;
      final monthRevenue = paidDues
          .where((d) => d.month == month && d.year == year)
          .fold<double>(0, (sum, d) => sum + d.totalDue);
      revenueByMonth[i] = monthRevenue;
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  title: 'Revenue (MTD)',
                  value: Formatters.currency(totalRevenue),
                  icon: Icons.trending_up,
                  color: AppColors.success,
                  onTap: () => nav.setTab('payments'),
                ),
                StatCard(
                  title: 'Total Students',
                  value: '$totalStudents',
                  icon: Icons.people,
                  color: AppColors.info,
                  onTap: () => nav.setTab('students'),
                ),
                StatCard(
                  title: 'Active Fleet',
                  value: '$activeBuses/$totalBuses',
                  icon: Icons.directions_bus,
                  color: AppColors.accent,
                  onTap: () => nav.setTab('buses'),
                ),
                StatCard(
                  title: 'Defaulters',
                  value: '$overdueDues',
                  icon: Icons.warning_amber,
                  color: AppColors.error,
                  subtitle: '$pendingDues pending',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue Chart
            Text('Revenue Trend (6 Months)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: revenueByMonth.values.isEmpty
                      ? 100
                      : (revenueByMonth.values
                                  .reduce((a, b) => a > b ? a : b) *
                              1.3)
                          .clamp(100, double.infinity),
                  barGroups: revenueByMonth.entries.map((e) {
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ]);
                  }).toList(),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final m = DateTime(now.year, now.month - (5 - v.toInt()), 1);
                          const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                          return Text(months[m.month - 1],
                              style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Health
            Text('Payment Health',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _healthItem('Paid', '${paidDues.length}', AppColors.paid),
                  _healthItem('Overdue', '$overdueDues', AppColors.overdue),
                  _healthItem('Pending', '$pendingDues', AppColors.unpaid),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _actionChip(Icons.person_add, 'Add Student', () => nav.setTab('students')),
                _actionChip(Icons.receipt_long, 'Reports', () => nav.setTab('reports')),
                _actionChip(Icons.gps_fixed, 'Track Buses', () => nav.setTab('tracking')),
                _actionChip(Icons.campaign, 'Broadcast', () => nav.setTab('notifications')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthItem(String label, String count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(count,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
