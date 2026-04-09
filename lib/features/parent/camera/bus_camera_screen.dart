import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (auth.user != null) context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final students = context.watch<StudentProvider>().students;

    // Permission gate
    if (auth.user?.preferences.camera != true) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.videocam_off_rounded, size: 36, color: AppColors.danger)),
          const SizedBox(height: 16),
          Text('CAMERA ACCESS DISABLED', style: AppTheme.labelStyle.copyWith(color: AppColors.slate800)),
          const SizedBox(height: 8),
          Text('Bus camera access has not been enabled for your account.\nContact your admin.',
              textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate400)),
        ],
      )));
    }

    if (students.isEmpty) return const EmptyState(icon: Icons.videocam_outlined, title: 'NO STUDENTS LINKED');

    final child = students.first;

    return Column(children: [
      // Bus info bar
      Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.slate950,
        child: Row(children: [
          const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(child.busNumber?.toUpperCase() ?? 'NO BUS', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(child.busPlate?.toUpperCase() ?? '', style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.5))),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
            ]),
          ),
        ]),
      ),

      // Camera feed placeholder
      Expanded(child: Container(
        color: Colors.black,
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Icon(Icons.videocam_rounded, size: 36, color: Colors.white.withOpacity(0.15)),
          ),
          const SizedBox(height: 16),
          Text('LIVE CAMERA FEED', style: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.3))),
          const SizedBox(height: 8),
          Text('CAMERA STREAM WILL APPEAR HERE\nWHEN THE BUS IS ACTIVE', textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 2, color: Colors.white.withOpacity(0.15))),
        ])),
      )),

      // Privacy notice
      Container(
        padding: const EdgeInsets.all(14),
        color: AppColors.slate50,
        child: Row(children: [
          const Icon(Icons.shield_rounded, size: 14, color: AppColors.slate400),
          const SizedBox(width: 8),
          Expanded(child: Text('CAMERA FEED IS ENCRYPTED AND ONLY VISIBLE TO AUTHORIZED PARENTS.',
              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.slate400))),
        ]),
      ),
    ]);
  }
}
