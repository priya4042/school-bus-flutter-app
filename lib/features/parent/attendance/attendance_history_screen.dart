import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    _loadAttendance();
  }

  void _loadAttendance() {
    final students = context.read<StudentProvider>().students;
    if (students.isNotEmpty) {
      final child = students[_selectedChild.clamp(0, students.length - 1)];
      context.read<AttendanceProvider>().fetchStudentAttendance(child.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final attendance = context.watch<AttendanceProvider>();

    if (students.isEmpty) {
      return const EmptyState(icon: Icons.fact_check_outlined, title: 'No students');
    }

    var records = attendance.records.toList();
    if (_typeFilter != 'ALL') {
      records = records.where((r) => r.type == _typeFilter).toList();
    }

    final present = attendance.totalPresent;
    final absent = attendance.totalAbsent;
    final rate = attendance.attendanceRate;

    return RefreshIndicator(
      onRefresh: () async => _loadAttendance(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Child selector
          if (students.length > 1) ...[
            SizedBox(height: 40, child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: students.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(students[i].fullName),
                  selected: i == _selectedChild,
                  onSelected: (_) { setState(() => _selectedChild = i); _loadAttendance(); },
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Stats
          Row(children: [
            Expanded(child: _miniStat('Present', '$present', AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('Absent', '$absent', AppColors.error)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('Pickups', '${attendance.pickupPresent}', AppColors.info)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('Drops', '${attendance.dropPresent}', AppColors.accent)),
          ]),
          const SizedBox(height: 12),

          // Attendance Rate
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Overall Attendance', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${rate.toStringAsFixed(1)}%',
                    style: TextStyle(fontWeight: FontWeight.w800,
                        color: rate > 80 ? AppColors.success : AppColors.error)),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: rate / 100,
                backgroundColor: AppColors.surface,
                color: rate > 80 ? AppColors.success : rate > 50 ? AppColors.warning : AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Type filter
          Row(children: [
            _chip('All', 'ALL'),
            _chip('Pickup', 'PICKUP'),
            _chip('Drop', 'DROP'),
          ]),
          const SizedBox(height: 12),

          // Records
          if (attendance.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (records.isEmpty)
            const EmptyState(icon: Icons.fact_check_outlined, title: 'No records')
          else
            ...records.map((r) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: r.isPresent ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                  child: Icon(r.isPresent ? Icons.check : Icons.close,
                      size: 18, color: r.isPresent ? AppColors.success : AppColors.error),
                ),
                title: Text('${r.type} - ${r.isPresent ? "Present" : "Absent"}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(Formatters.dateTime(r.createdAt),
                    style: const TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.isPickup ? AppColors.info.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(r.type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: r.isPickup ? AppColors.info : AppColors.accent)),
                ),
              ),
            )),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
      ]),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(label: Text(label), selected: selected,
          onSelected: (_) => setState(() => _typeFilter = value)),
    );
  }
}
