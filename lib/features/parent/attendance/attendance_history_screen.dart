import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});
  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int _selectedChild = 0;
  String _typeFilter = 'ALL';
  bool _showFilters = false;
  int? _filterYear;
  int? _filterMonth;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    _loadAttendance();
  }

  void _loadAttendance() {
    final students = context.read<StudentProvider>().students;
    if (students.isNotEmpty) {
      context.read<AttendanceProvider>().fetchStudentAttendance(
          students[_selectedChild.clamp(0, students.length - 1)].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final attendance = context.watch<AttendanceProvider>();

    if (students.isEmpty) return const EmptyState(icon: Icons.fact_check_outlined, title: 'NO STUDENTS');

    var records = attendance.records.toList();
    if (_typeFilter != 'ALL') records = records.where((r) => r.type == _typeFilter).toList();
    if (_filterYear != null) records = records.where((r) => r.createdAt.year == _filterYear).toList();
    if (_filterMonth != null) records = records.where((r) => r.createdAt.month == _filterMonth).toList();

    final present = records.where((r) => r.isPresent).length;
    final absent = records.where((r) => !r.isPresent).length;
    final total = present + absent;
    final rate = total > 0 ? (present / total) * 100 : 0.0;
    final pickups = records.where((r) => r.isPickup && r.isPresent).length;
    final drops = records.where((r) => !r.isPickup && r.isPresent).length;

    // Active filter count
    int filterCount = 0;
    if (_filterYear != null) filterCount++;
    if (_filterMonth != null) filterCount++;

    // Group by date
    final grouped = <String, List<dynamic>>{};
    for (final r in records) {
      final key = Formatters.date(r.createdAt);
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAttendance(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Child selector
          if (students.length > 1) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200.withOpacity(0.5))),
              child: Row(children: List.generate(students.length, (i) {
                final sel = i == _selectedChild;
                return Expanded(child: GestureDetector(
                  onTap: () { setState(() => _selectedChild = i); _loadAttendance(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(students[i].fullName.split(' ').first.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
                          color: sel ? AppColors.primary : AppColors.slate400))),
                  ),
                ));
              })),
            ),
            const SizedBox(height: 16),
          ],

          // Stats row
          Row(children: [
            _miniStat('PRESENT', '$present', AppColors.success),
            const SizedBox(width: 6),
            _miniStat('ABSENT', '$absent', AppColors.danger),
            const SizedBox(width: 6),
            _miniStat('PICKUPS', '$pickups', AppColors.blue500),
            const SizedBox(width: 6),
            _miniStat('DROPS', '$drops', AppColors.indigo500),
          ]),
          const SizedBox(height: 12),

          // Rate bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.slate200)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('OVERALL ATTENDANCE', style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                Text('${rate.toStringAsFixed(1)}%', style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w900,
                    color: rate > 80 ? AppColors.success : rate > 50 ? AppColors.warning : AppColors.danger)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rate / 100, minHeight: 6,
                  backgroundColor: AppColors.slate100,
                  color: rate > 80 ? AppColors.success : rate > 50 ? AppColors.warning : AppColors.danger,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // Type filter + filter toggle
          Row(children: [
            _typeChip('ALL'), _typeChip('PICKUP'), _typeChip('DROP'),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showFilters = !_showFilters),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.slate200)),
                child: Stack(children: [
                  const Icon(Icons.filter_list_rounded, size: 18, color: AppColors.slate500),
                  if (filterCount > 0) Positioned(right: -2, top: -2, child: Container(
                    width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: Center(child: Text('$filterCount', style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900))),
                  )),
                ]),
              ),
            ),
          ]),

          // Expanded filters
          if (_showFilters) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
                  value: _filterYear, isExpanded: true,
                  hint: Text('YEAR', style: AppTheme.labelXs),
                  items: [
                    DropdownMenuItem(value: null, child: Text('ALL YEARS', style: AppTheme.labelXs.copyWith(color: AppColors.slate700))),
                    ...List.generate(5, (i) => DateTime.now().year - i).map((y) =>
                        DropdownMenuItem(value: y, child: Text('$y', style: AppTheme.labelXs.copyWith(color: AppColors.slate700)))),
                  ],
                  onChanged: (v) => setState(() { _filterYear = v; _filterMonth = null; }),
                )),
              )),
              const SizedBox(width: 8),
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.slate200)),
                child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
                  value: _filterMonth, isExpanded: true,
                  hint: Text('MONTH', style: AppTheme.labelXs),
                  items: [
                    DropdownMenuItem(value: null, child: Text('ALL MONTHS', style: AppTheme.labelXs.copyWith(color: AppColors.slate700))),
                    ...List.generate(12, (i) => i + 1).map((m) =>
                        DropdownMenuItem(value: m, child: Text(Formatters.monthYear(m, _filterYear ?? DateTime.now().year).split(' ').first.toUpperCase(),
                            style: AppTheme.labelXs.copyWith(color: AppColors.slate700)))),
                  ],
                  onChanged: (v) => setState(() => _filterMonth = v),
                )),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { _filterYear = null; _filterMonth = null; }),
                child: Text('CLEAR ALL', style: AppTheme.labelXs.copyWith(color: AppColors.primary)),
              ),
            ]),
          ],
          const SizedBox(height: 16),

          // Records grouped by date
          if (attendance.isLoading)
            const MiniLoader()
          else if (grouped.isEmpty)
            const EmptyState(icon: Icons.fact_check_outlined, title: 'NO RECORDS')
          else
            ...grouped.entries.map((entry) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(entry.key.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
              ),
              ...entry.value.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate100)),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: r.isPresent ? AppColors.emerald50 : AppColors.red50,
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(r.isPresent ? Icons.check_rounded : Icons.close_rounded,
                        size: 16, color: r.isPresent ? AppColors.emerald600 : AppColors.red500),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.type} — ${r.isPresent ? "PRESENT" : "ABSENT"}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                    Text(Formatters.timeOnly(r.createdAt), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: r.isPickup ? AppColors.blue50 : AppColors.indigo500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(r.type, style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1,
                        color: r.isPickup ? AppColors.blue600 : AppColors.indigo500)),
                  ),
                ]),
              )),
            ])),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1, color: color.withOpacity(0.7))),
      ]),
    ));
  }

  Widget _typeChip(String type) {
    final sel = _typeFilter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(type, style: GoogleFonts.plusJakartaSans(
            fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
            color: sel ? Colors.white : AppColors.slate500)),
        ),
      ),
    );
  }
}
