import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/route_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _type = 'PICKUP';
  DateTime _selectedDate = DateTime.now();
  String? _selectedRouteId;
  final Map<String, String> _marks = {};

  @override
  void initState() {
    super.initState();
    context.read<StudentProvider>().fetchStudents();
    context.read<RouteProvider>().fetchRoutes();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await context.read<AttendanceProvider>().fetchAttendance(date: dateStr, type: _type);
    final records = context.read<AttendanceProvider>().records;
    _marks.clear();
    for (final r in records) _marks[r.studentId] = r.status;
    setState(() {});
  }

  Future<void> _markAttendance(String studentId, String status) async {
    setState(() => _marks[studentId] = status);
    await context.read<AttendanceProvider>().markAttendance(
      studentId: studentId, type: _type, status: status);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context,
      initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime.now());
    if (picked != null) { setState(() => _selectedDate = picked); _loadAttendance(); }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().activeStudents;
    final routes = context.watch<RouteProvider>().routes;
    final attendance = context.watch<AttendanceProvider>();

    // Filter by route
    final filtered = _selectedRouteId == null ? students
        : students.where((s) => s.routeId == _selectedRouteId).toList();

    return Column(children: [
      // Controls
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        // Shift toggle + Date
        Row(children: [
          // Shift toggle
          Container(padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _shiftBtn('PICKUP', 'PICKUP', Icons.wb_sunny_rounded),
              const SizedBox(width: 4),
              _shiftBtn('DROP', 'DROP', Icons.nights_stay_rounded),
            ]),
          ),
          const Spacer(),
          // Date picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(_selectedDate).toUpperCase(),
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate800)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Route selector grid
        if (routes.isNotEmpty) ...[
          Text('SELECT ROUTE', style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
          const SizedBox(height: 8),
          SizedBox(height: 36, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: routes.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                final sel = _selectedRouteId == null;
                return Padding(padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () { setState(() => _selectedRouteId = null); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.slate100,
                        borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text('ALL', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
                        color: sel ? Colors.white : AppColors.slate500))),
                    ),
                  ),
                );
              }
              final r = routes[i - 1];
              final sel = _selectedRouteId == r.id;
              return Padding(padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () { setState(() => _selectedRouteId = r.id); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.slate100,
                      borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(r.routeName.toUpperCase(), style: TextStyle(fontFamily: 'PlusJakartaSans', 
                      fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1,
                      color: sel ? Colors.white : AppColors.slate500), maxLines: 1)),
                  ),
                ),
              );
            },
          )),
        ],
      ])),

      // Student list
      Expanded(
        child: attendance.isLoading ? const MiniLoader()
            : filtered.isEmpty ? const EmptyState(icon: Icons.school_rounded, title: 'NO STUDENTS')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  final mark = _marks[s.id];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate100)),
                    child: Row(children: [
                      // Status avatar
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: mark == 'PRESENT' ? AppColors.success.withOpacity(0.1) : mark == 'ABSENT' ? AppColors.danger.withOpacity(0.1) : AppColors.slate50,
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(
                          mark == 'PRESENT' ? Icons.check_circle_rounded : mark == 'ABSENT' ? Icons.cancel_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18, color: mark == 'PRESENT' ? AppColors.success : mark == 'ABSENT' ? AppColors.danger : AppColors.slate300)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.fullName.toUpperCase(), style: TextStyle(fontFamily: 'PlusJakartaSans', 
                          fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
                        Text('${s.admissionNumber} • ${s.displayGrade}'.toUpperCase(),
                            style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
                      ])),
                      // Present / Absent buttons
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        GestureDetector(
                          onTap: () => _markAttendance(s.id, 'PRESENT'),
                          child: Container(width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: mark == 'PRESENT' ? AppColors.success : AppColors.slate50,
                              borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.check_rounded, size: 16,
                                color: mark == 'PRESENT' ? Colors.white : AppColors.slate400)),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _markAttendance(s.id, 'ABSENT'),
                          child: Container(width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: mark == 'ABSENT' ? AppColors.danger : AppColors.slate50,
                              borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.close_rounded, size: 16,
                                color: mark == 'ABSENT' ? Colors.white : AppColors.slate400)),
                        ),
                        // Emergency phone
                        if (s.parentPhone != null && s.parentPhone!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse('tel:${s.parentPhone}')),
                            child: Container(width: 32, height: 32,
                              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary)),
                          ),
                        ],
                      ]),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _shiftBtn(String label, String value, IconData icon) {
    final sel = _type == value;
    return GestureDetector(
      onTap: () { setState(() => _type = value); _loadAttendance(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9)),
        child: Row(children: [
          Icon(icon, size: 14, color: sel ? Colors.white : AppColors.slate400),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
              color: sel ? Colors.white : AppColors.slate500)),
        ]),
      ),
    );
  }
}
