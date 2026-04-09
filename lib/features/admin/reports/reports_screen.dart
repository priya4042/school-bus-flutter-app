import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _deletedStudents = [];
  bool _loadingDeleted = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    context.read<FeeProvider>().fetchDues();
    context.read<FeeProvider>().fetchDefaulters();
    context.read<StudentProvider>().fetchStudents();
    _loadDeletedStudents();
  }

  Future<void> _loadDeletedStudents() async {
    setState(() => _loadingDeleted = true);
    try {
      final res = await Supabase.instance.client.from('deleted_students')
          .select('*').order('deleted_at', ascending: false).limit(50);
      if (mounted) setState(() { _deletedStudents = List<Map<String, dynamic>>.from(res); _loadingDeleted = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDeleted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200.withOpacity(0.5))),
        child: TabBar(
          controller: _tabCtrl, isScrollable: true, tabAlignment: TabAlignment.start,
          indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.slate400,
          tabs: const [Tab(text: 'REVENUE'), Tab(text: 'ROUTES'), Tab(text: 'DEFAULTERS'), Tab(text: 'HISTORY')],
        ),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _buildRevenueTab(),
        _buildRoutesTab(),
        _buildDefaultersTab(),
        _buildHistoryTab(),
      ])),
    ]);
  }

  // ===== REVENUE TAB =====
  Widget _buildRevenueTab() {
    final fees = context.watch<FeeProvider>();
    final paid = fees.dues.where((d) => d.isPaid).toList();
    final unpaid = fees.dues.where((d) => !d.isPaid).toList();
    final totalRevenue = paid.fold<double>(0, (s, d) => s + d.totalDue);
    final totalOutstanding = unpaid.fold<double>(0, (s, d) => s + d.totalDue);
    final collectionRate = fees.dues.isEmpty ? 0.0 : (paid.length / fees.dues.length) * 100;

    // Monthly revenue data (last 6 months)
    final now = DateTime.now();
    final monthlyData = <FlSpot>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final rev = paid.where((d) => d.month == m.month && d.year == m.year)
          .fold<double>(0, (s, d) => s + d.totalDue);
      monthlyData.add(FlSpot((5 - i).toDouble(), rev));
    }
    final maxY = monthlyData.isEmpty ? 100.0 : monthlyData.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3;

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _summaryCard('TOTAL REVENUE', Formatters.currency(totalRevenue), AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('OUTSTANDING', Formatters.currency(totalOutstanding), AppColors.danger)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _summaryCard('COLLECTION RATE', '${collectionRate.toStringAsFixed(1)}%', AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('TOTAL STUDENTS', '${context.watch<StudentProvider>().activeStudents.length}', AppColors.slate800)),
      ]),
      const SizedBox(height: 20),

      Text('MONTHLY GROWTH VELOCITY', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
      const SizedBox(height: 12),
      Container(
        height: 220, padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardLargeDecoration,
        child: LineChart(LineChartData(
          maxY: maxY.clamp(100, double.infinity),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: monthlyData,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0)],
                  )),
            ),
          ],
          gridData: FlGridData(show: true,
              getDrawingHorizontalLine: (v) => FlLine(color: AppColors.slate100, strokeWidth: 1, dashArray: [3, 3])),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              getTitlesWidget: (v, _) {
                final m = DateTime(now.year, now.month - (5 - v.toInt()), 1);
                const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
                return Text(months[m.month - 1], style: AppTheme.labelXs);
              })),
          ),
        )),
      ),
      const SizedBox(height: 20),

      // Export button
      Container(
        width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.slate950, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.archive_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EXPORT ARCHIVES', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
            Text('DOWNLOAD COMPLETE FINANCIAL DATA', style: GoogleFonts.plusJakartaSans(
              fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white.withOpacity(0.4))),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
        ]),
      ),
    ]));
  }

  // ===== ROUTES TAB =====
  Widget _buildRoutesTab() {
    final fees = context.watch<FeeProvider>();
    final paid = fees.dues.where((d) => d.isPaid).toList();
    final totalRevenue = paid.fold<double>(0, (s, d) => s + d.totalDue);
    final collectionRate = fees.dues.isEmpty ? 0.0 : (paid.length / fees.dues.length) * 100;

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('COLLECTION DISTRIBUTION BY ZONE', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
      const SizedBox(height: 12),
      Container(
        height: 220, padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardLargeDecoration,
        child: Row(children: [
          Expanded(child: PieChart(PieChartData(
            sections: [
              PieChartSectionData(value: 35, color: AppColors.primary, title: '35%',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              PieChartSectionData(value: 25, color: AppColors.success, title: '25%',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              PieChartSectionData(value: 22, color: AppColors.warning, title: '22%',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              PieChartSectionData(value: 18, color: AppColors.indigo500, title: '18%',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
            ],
            sectionsSpace: 2, centerSpaceRadius: 30,
          ))),
          const SizedBox(width: 16),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _legend('NORTH ZONE', AppColors.primary),
            const SizedBox(height: 6),
            _legend('SOUTH CITY', AppColors.success),
            const SizedBox(height: 6),
            _legend('EAST HIGHLAND', AppColors.warning),
            const SizedBox(height: 6),
            _legend('WEST LINK', AppColors.indigo500),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      Text('EFFICIENCY METRICS', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(20), decoration: AppTheme.cardLargeDecoration,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOP PERFORMING ROUTE', style: AppTheme.labelXs),
              const SizedBox(height: 4),
              Text('NORTH ZONE', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            ]),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('+18.4%', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.success))),
          ]),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AVERAGE FEE RECOVERY', style: AppTheme.labelXs),
              const SizedBox(height: 4),
              Text('${collectionRate.toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            ]),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('HEALTHY', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.success))),
          ]),
        ]),
      ),
    ]));
  }

  // ===== DEFAULTERS TAB =====
  Widget _buildDefaultersTab() {
    final fees = context.watch<FeeProvider>();
    final defaulters = fees.defaulters;

    if (defaulters.isEmpty) return const EmptyState(icon: Icons.check_circle_rounded, title: 'NO DEFAULTERS');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: defaulters.length,
      itemBuilder: (_, i) {
        final d = defaulters[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.slate100)),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text((d.studentName ?? 'S')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 14)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((d.studentName ?? 'UNKNOWN').toUpperCase(), style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
              Text(d.monthLabel.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(Formatters.currencyFull(d.totalDue), style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.danger)),
              GestureDetector(
                onTap: () {}, // Send notice
                child: Text('SEND NOTICE', style: AppTheme.labelXs.copyWith(color: AppColors.primary)),
              ),
            ]),
          ]),
        );
      },
    );
  }

  // ===== HISTORY TAB (Deleted Students Archive) =====
  Widget _buildHistoryTab() {
    if (_loadingDeleted) return const MiniLoader();
    if (_deletedStudents.isEmpty) return const EmptyState(icon: Icons.history_rounded, title: 'NO DELETED RECORDS');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedStudents.length,
      itemBuilder: (_, i) {
        final s = _deletedStudents[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate100)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(((s['full_name'] ?? 'S') as String)[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(((s['full_name'] ?? 'UNKNOWN') as String).toUpperCase(), style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                Text('${s['admission_number'] ?? ""}'.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
              ])),
              StatusBadge(label: ((s['student_status'] ?? 'DELETED') as String).toUpperCase(),
                  color: AppColors.slate500, bgColor: AppColors.slate100),
            ]),
            const Divider(height: 16),
            Row(children: [
              _archiveInfo('CLASS', '${s['grade'] ?? ""} ${s['section'] ?? ""}'.trim().toUpperCase()),
              _archiveInfo('PARENT', ((s['parent_name'] ?? 'N/A') as String).toUpperCase()),
              _archiveInfo('FEE RECORDS', '${s['fee_record_count'] ?? 0} / ${s['paid_fee_record_count'] ?? 0} PAID'),
            ]),
            if ((s['outstanding_amount'] ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Text('OUTSTANDING: ${Formatters.currencyFull((s['outstanding_amount'] as num).toDouble())}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.danger)),
            ],
          ]),
        );
      },
    );
  }

  Widget _archiveInfo(String label, String value) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTheme.labelXs),
      Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate700)),
    ]));
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: color.withOpacity(0.7))),
      ]),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.slate600)),
    ]);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }
}
