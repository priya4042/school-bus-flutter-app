import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class ParentRoutesScreen extends StatefulWidget {
  const ParentRoutesScreen({super.key});

  @override
  State<ParentRoutesScreen> createState() => _ParentRoutesScreenState();
}

class _ParentRoutesScreenState extends State<ParentRoutesScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AppAuthProvider>();
    if (auth.user != null) {
      context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;

    if (students.isEmpty) {
      return const EmptyState(
          icon: Icons.route_outlined,
          title: 'No children found',
          subtitle: 'Contact admin to link your child\'s profile');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (_, i) {
        final s = students[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Student header
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(s.fullName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(s.admissionNumber, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ])),
              ]),
              const Divider(height: 24),

              // Route info
              _infoRow(Icons.route, 'Route', s.routeName ?? 'Not Assigned'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _infoRow(Icons.location_on, 'Start', 'N/A')),
                Expanded(child: _infoRow(Icons.flag, 'End', 'N/A')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _infoRow(Icons.directions_bus, 'Bus', s.busNumber ?? 'N/A')),
                Expanded(child: _infoRow(Icons.confirmation_number, 'Plate', s.busPlate ?? 'N/A')),
              ]),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.pin_drop, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text('Boarding: ${s.boardingPoint ?? "Not set"}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.info)),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ]);
  }
}
