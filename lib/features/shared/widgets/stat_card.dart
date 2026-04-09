import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// Exact DashboardCard: bg-white p-6 border border-slate-200 rounded-xl shadow-sm
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // Icon: bg-{color}-50 text-{color}-600 p-3 rounded-lg
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: c, size: 20),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.slate300),
          ]),
          const SizedBox(height: 14),
          // Value: text-3xl font-bold
          Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.slate800, letterSpacing: -1)),
          const SizedBox(height: 4),
          // Title: text-sm font-medium text-slate-500 uppercase tracking-wider
          Text(title.toUpperCase(), style: GoogleFonts.plusJakartaSans(
            fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.slate500,
            letterSpacing: 2)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w700, color: c)),
          ],
        ]),
      ),
    );
  }
}

/// Status badge: px-3 py-1.5 rounded-full text-[9px] font-black uppercase
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;
  final Color? borderColor;

  const StatusBadge({super.key, required this.label, required this.color, this.bgColor, this.borderColor});

  factory StatusBadge.fromStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return StatusBadge(label: 'PAID', color: AppColors.success,
            bgColor: AppColors.success.withOpacity(0.1), borderColor: AppColors.success.withOpacity(0.1));
      case 'OVERDUE':
        return StatusBadge(label: 'OVERDUE', color: AppColors.danger,
            bgColor: AppColors.danger.withOpacity(0.1), borderColor: AppColors.danger.withOpacity(0.1));
      case 'PENDING': case 'UNPAID':
        return StatusBadge(label: 'PENDING', color: AppColors.amber600,
            bgColor: AppColors.amber50, borderColor: AppColors.amber500.withOpacity(0.2));
      case 'FUTURE':
        return StatusBadge(label: 'FUTURE', color: AppColors.slate500,
            bgColor: AppColors.slate100, borderColor: AppColors.slate200);
      case 'ACTIVE':
        return StatusBadge(label: 'ACTIVE', color: AppColors.success,
            bgColor: AppColors.emerald50, borderColor: AppColors.success.withOpacity(0.1));
      case 'INACTIVE':
        return StatusBadge(label: 'INACTIVE', color: AppColors.danger,
            bgColor: AppColors.red50, borderColor: AppColors.danger.withOpacity(0.1));
      default:
        return StatusBadge(label: status.toUpperCase(), color: AppColors.slate500,
            bgColor: AppColors.slate100, borderColor: AppColors.slate200);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? color.withOpacity(0.1)),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: color)),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 56, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(title.toUpperCase(), style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.slate400)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate400)),
          ],
        ]),
      ),
    );
  }
}

/// Mini loader matching original: SVG ring with gradient
class MiniLoader extends StatelessWidget {
  const MiniLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              backgroundColor: AppColors.slate100,
            ),
          ),
          const SizedBox(height: 16),
          // SBW text
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, AppColors.cyan500],
            ).createShader(bounds),
            child: Text('SBW', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text('CLOUD SYNC IN PROGRESS', style: GoogleFonts.plusJakartaSans(
            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppColors.slate400)),
        ]),
      ),
    );
  }
}
