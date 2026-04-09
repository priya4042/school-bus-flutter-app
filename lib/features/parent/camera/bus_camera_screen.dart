import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class BusCameraScreen extends StatefulWidget {
  const BusCameraScreen({super.key});

  @override
  State<BusCameraScreen> createState() => _BusCameraScreenState();
}

class _BusCameraScreenState extends State<BusCameraScreen> {
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
    final auth = context.watch<AppAuthProvider>();
    final students = context.watch<StudentProvider>().students;

    // Check camera permission
    final hasPermission = auth.user?.preferences.camera == true;

    if (!hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_off, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            const Text('Camera Access Disabled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Bus camera access has not been enabled for your account. Contact your admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }

    if (students.isEmpty) {
      return const EmptyState(icon: Icons.videocam_outlined, title: 'No students linked');
    }

    final child = students.first;

    return Column(children: [
      // Bus Info Bar
      Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.primary,
        child: Row(children: [
          const Icon(Icons.directions_bus, color: Colors.white),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(child.busNumber ?? 'No Bus',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            Text(child.busPlate ?? '',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.circle, size: 8, color: AppColors.success),
              SizedBox(width: 4),
              Text('Live', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),

      // Camera Feed Placeholder
      Expanded(
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.videocam, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text('Live Camera Feed',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
              SizedBox(height: 8),
              Text('Camera stream will appear here\nwhen the bus is active',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 13)),
            ]),
          ),
        ),
      ),

      // Privacy notice
      Container(
        padding: const EdgeInsets.all(12),
        color: AppColors.surface,
        child: const Row(children: [
          Icon(Icons.shield, size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Camera feed is encrypted and only visible to authorized parents.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          )),
        ]),
      ),
    ]);
  }
}
