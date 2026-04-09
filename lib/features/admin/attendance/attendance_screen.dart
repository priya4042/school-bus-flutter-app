import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _type = 'PICKUP';
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _marks = {}; // studentId -> PRESENT/ABSENT

  @override
  void initState() {
    super.initState();
    context.read<StudentProvider>().fetchStudents();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await context.read<AttendanceProvider>().fetchAttendance(date: dateStr, type: _type);
    final records = context.read<AttendanceProvider>().records;
    _marks.clear();
    for (final r in records) {
      _marks[r.studentId] = r.status;
    }
    setState(() {});
  }

  Future<void> _markAttendance(String studentId, String status) async {
    setState(() => _marks[studentId] = status);
    await context.read<AttendanceProvider>().markAttendance(
      studentId: studentId,
      type: _type,
      status: status,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().activeStudents;
    final attendance = context.watch<AttendanceProvider>();

    return Column(
      children: [
        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Date picker + Type toggle
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ToggleButtons(
                isSelected: [_type == 'PICKUP', _type == 'DROP'],
                onPressed: (i) {
                  setState(() => _type = i == 0 ? 'PICKUP' : 'DROP');
                  _loadAttendance();
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: AppColors.primary,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Pickup')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Drop')),
                ],
              ),
            ]),
          ]),
        ),

        // Student List
        Expanded(
          child: attendance.isLoading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
                  ? const Center(child: Text('No active students'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final s = students[i];
                        final mark = _marks[s.id];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: mark == 'PRESENT'
                                  ? AppColors.success.withOpacity(0.1)
                                  : mark == 'ABSENT'
                                      ? AppColors.error.withOpacity(0.1)
                                      : AppColors.surface,
                              child: Icon(
                                mark == 'PRESENT' ? Icons.check_circle : mark == 'ABSENT' ? Icons.cancel : Icons.radio_button_unchecked,
                                color: mark == 'PRESENT' ? AppColors.success : mark == 'ABSENT' ? AppColors.error : AppColors.textSecondary,
                              ),
                            ),
                            title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(s.admissionNumber, style: const TextStyle(fontSize: 13)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check_circle_outline,
                                      color: mark == 'PRESENT' ? AppColors.success : AppColors.textSecondary),
                                  onPressed: () => _markAttendance(s.id, 'PRESENT'),
                                ),
                                IconButton(
                                  icon: Icon(Icons.cancel_outlined,
                                      color: mark == 'ABSENT' ? AppColors.error : AppColors.textSecondary),
                                  onPressed: () => _markAttendance(s.id, 'ABSENT'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
