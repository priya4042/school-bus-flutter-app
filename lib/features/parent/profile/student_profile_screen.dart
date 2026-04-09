import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/providers/attendance_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  int _selectedChild = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;

    if (students.isEmpty) {
      return const EmptyState(icon: Icons.person_outlined, title: 'No students linked');
    }

    final child = students[_selectedChild.clamp(0, students.length - 1)];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Child Selector
          if (students.length > 1) ...[
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: students.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(students[i].fullName),
                    selected: i == _selectedChild,
                    onSelected: (_) => setState(() => _selectedChild = i),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ID Card Style
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    child: Text(child.fullName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Text(child.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text(child.admissionNumber,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: child.isActive ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(child.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(children: [
                  _miniInfo('Grade', child.displayGrade),
                  _miniInfo('Bus', child.busNumber ?? 'N/A'),
                  _miniInfo('Route', child.routeName ?? 'N/A'),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Transit Details
          const Text('Transit Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _detailRow(Icons.location_on, 'Boarding Point', child.boardingPoint ?? 'Not set'),
              const Divider(height: 20),
              _detailRow(Icons.directions_bus, 'Bus Assigned', '${child.busNumber ?? "N/A"} (${child.busPlate ?? "N/A"})'),
              const Divider(height: 20),
              _detailRow(Icons.route, 'Route', child.routeName ?? 'Not assigned'),
            ]),
          )),
          const SizedBox(height: 20),

          // Fee Summary
          const Text('Fee Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _detailRow(Icons.currency_rupee, 'Monthly Fee', Formatters.currencyFull(child.monthlyFee)),
              const Divider(height: 20),
              _detailRow(Icons.calendar_today, 'Enrolled Since',
                  child.createdAt != null ? Formatters.date(child.createdAt!) : 'N/A'),
            ]),
          )),

          if (child.parentPhone != null) ...[
            const SizedBox(height: 20),
            const Text('Contact', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: _detailRow(Icons.phone, 'Parent Phone', child.parentPhone!),
            )),
          ],
        ]),
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Expanded(child: Column(children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]));
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.textSecondary),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ])),
    ]);
  }
}
