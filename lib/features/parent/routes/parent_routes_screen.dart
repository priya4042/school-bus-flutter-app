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
    if (auth.user != null) context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    if (students.isEmpty) return const EmptyState(icon: Icons.route_outlined, title: 'NO CHILDREN FOUND',
        subtitle: 'Contact admin to link your child\'s profile');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (_, i) {
        final s = students[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardLargeDecoration,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(s.fullName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.fullName.toUpperCase(), style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
                Text(s.admissionNumber.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
              ])),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _infoRow(Icons.route_rounded, 'ROUTE', s.routeName ?? 'NOT ASSIGNED'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _infoRow(Icons.location_on_rounded, 'START', 'N/A')),
              Expanded(child: _infoRow(Icons.flag_rounded, 'END', 'N/A')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _infoRow(Icons.directions_bus_rounded, 'BUS', s.busNumber ?? 'N/A')),
              Expanded(child: _infoRow(Icons.confirmation_number_rounded, 'PLATE', s.busPlate ?? 'N/A')),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.blue50.withOpacity(0.5), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.blue100)),
              child: Row(children: [
                const Icon(Icons.pin_drop_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('BOARDING: ${(s.boardingPoint ?? "NOT SET").toUpperCase()}', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.primary)),
              ]),
            ),
          ]),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: AppColors.slate400),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.labelXs),
        Text(value.toUpperCase(), style: TextStyle(fontFamily: 'PlusJakartaSans', 
          fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
      ]),
    ]);
  }
}
