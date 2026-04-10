import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool _showAddChild = false;
  bool _showFuture = false;
  final _childNameCtrl = TextEditingController();
  final _childAdmCtrl = TextEditingController();
  final _childGradeCtrl = TextEditingController();
  final _childSectionCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    await context.read<FeeProvider>().fetchParentDues(auth.user!.id);
    final students = context.read<StudentProvider>().students;
    if (students.isNotEmpty) {
      context.read<AttendanceProvider>().fetchStudentAttendance(
          students[_selectedChild.clamp(0, students.length - 1)].id, limit: 10);
    }
  }

  Future<void> _addChild() async {
    if (_childNameCtrl.text.trim().isEmpty) return;
    final auth = context.read<AppAuthProvider>();
    final admission = _childAdmCtrl.text.trim().isNotEmpty
        ? _childAdmCtrl.text.trim().toUpperCase()
        : 'PARENT-${DateTime.now().millisecondsSinceEpoch}';
    try {
      await Supabase.instance.client.from('students').insert({
        'full_name': _childNameCtrl.text.trim(),
        'admission_number': admission,
        'grade': _childGradeCtrl.text.trim(),
        'section': _childSectionCtrl.text.trim(),
        'parent_id': auth.user!.id,
        'status': 'ACTIVE',
      });
      _childNameCtrl.clear(); _childAdmCtrl.clear(); _childGradeCtrl.clear(); _childSectionCtrl.clear();
      setState(() => _showAddChild = false);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Child added! Admin will complete the profile.'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final fees = context.watch<FeeProvider>();
    final attendance = context.watch<AttendanceProvider>();

    if (students.isEmpty) {
      return RefreshIndicator(onRefresh: _load, child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: MediaQuery.of(context).size.height * 0.6,
          child: const EmptyState(icon: Icons.person_outlined, title: 'NO STUDENTS LINKED')),
      ));
    }

    final child = students[_selectedChild.clamp(0, students.length - 1)];
    final childDues = fees.dues.where((d) => d.studentId == child.id).toList();
    final paidTotal = childDues.where((d) => d.isPaid).fold<double>(0, (s, d) => s + d.totalDue);
    final unpaidDues = childDues.where((d) => !d.isPaid).toList();
    final nextDue = unpaidDues.isNotEmpty ? unpaidDues.last : null;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Child selector + Add button
          Row(children: [
            if (students.length > 1)
              Expanded(child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200.withOpacity(0.5))),
                child: Row(children: List.generate(students.length, (i) {
                  final sel = i == _selectedChild;
                  return Expanded(child: GestureDetector(
                    onTap: () { setState(() => _selectedChild = i);
                      context.read<AttendanceProvider>().fetchStudentAttendance(students[i].id, limit: 10); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: sel ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : null,
                      ),
                      child: Center(child: Text(students[i].fullName.split(' ').first.toUpperCase(),
                        style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
                            color: sel ? AppColors.primary : AppColors.slate400), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ),
                  ));
                })),
              )),
            if (students.length > 1) const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _showAddChild = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.primaryButtonShadow()),
                child: Text('+ ADD CHILD', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                  fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // ===== ADD CHILD FORM =====
          if (_showAddChild) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.slate100)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ADD NEW CHILD', style: AppTheme.headingSmall),
                const SizedBox(height: 16),
                TextField(controller: _childNameCtrl, decoration: AppTheme.inputDecoration('Child Full Name *')),
                const SizedBox(height: 12),
                TextField(controller: _childAdmCtrl, decoration: AppTheme.inputDecoration('Admission Number')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: _childGradeCtrl, decoration: AppTheme.inputDecoration('Grade'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _childSectionCtrl, decoration: AppTheme.inputDecoration('Section'))),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: SizedBox(height: 48, child: ElevatedButton(
                    onPressed: () { setState(() => _showAddChild = false); _childNameCtrl.clear(); _childAdmCtrl.clear(); },
                    style: AppTheme.secondaryButton, child: const Text('CANCEL')))),
                  const SizedBox(width: 12),
                  Expanded(child: SizedBox(height: 48, child: ElevatedButton(
                    onPressed: _addChild, style: AppTheme.primaryButton, child: const Text('ADD CHILD')))),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // ===== ID CARD =====
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.slate100), boxShadow: AppTheme.premiumShadow),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              // Dark header with skew effect
              Container(
                height: 80,
                width: double.infinity,
                color: AppColors.slate950,
              ),
              Transform.translate(
                offset: const Offset(0, -40),
                child: Column(children: [
                  // Avatar
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(20)),
                      child: Center(child: Icon(Icons.person_rounded, size: 36, color: AppColors.slate300)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(child.fullName, style: TextStyle(fontFamily: 'PlusJakartaSans', 
                    fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate900)),
                  Text('${child.grade ?? ''} - ${child.section ?? ''}'.toUpperCase(),
                    style: AppTheme.labelSmall.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  StatusBadge.fromStatus(child.isActive ? 'ACTIVE' : 'INACTIVE'),
                  const SizedBox(height: 16),
                  const Divider(indent: 32, endIndent: 32),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      _detailRow(Icons.badge_rounded, 'ADMISSION', child.admissionNumber),
                      _detailRow(Icons.calendar_today_rounded, 'ENROLLED', child.createdAt != null ? Formatters.date(child.createdAt!) : 'N/A'),
                      _detailRow(Icons.phone_rounded, 'CONTACT', child.parentPhone ?? 'N/A'),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ===== TRANSIT DETAILS (Dark card) =====
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.slate950,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TRANSIT DETAILS', style: TextStyle(fontFamily: 'PlusJakartaSans', 
                fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: Colors.white)),
              const SizedBox(height: 20),
              _transitRow(Icons.location_on_rounded, 'BOARDING POINT', child.boardingPoint ?? 'Not set'),
              const SizedBox(height: 14),
              _transitRow(Icons.directions_bus_rounded, 'BUS ASSIGNED', '${child.busNumber ?? "N/A"} (${child.busPlate ?? "N/A"})'),
              const SizedBox(height: 14),
              _transitRow(Icons.route_rounded, 'ROUTE', child.routeName ?? 'Not assigned'),
            ]),
          ),
          const SizedBox(height: 16),

          // ===== FEE STATUS =====
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardXlDecoration,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('FEE STATUS', style: AppTheme.headingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: unpaidDues.isEmpty ? AppColors.emerald50 : AppColors.red50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(unpaidDues.isEmpty ? Icons.check_circle_rounded : Icons.warning_rounded,
                        size: 14, color: unpaidDues.isEmpty ? AppColors.emerald600 : AppColors.red500),
                    const SizedBox(width: 4),
                    Text(unpaidDues.isEmpty ? 'ALL CLEAR' : 'DUES PENDING',
                        style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
                            color: unpaidDues.isEmpty ? AppColors.emerald600 : AppColors.red500)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _feeStatBox(Icons.check_circle_rounded, AppColors.success, 'TOTAL PAID', Formatters.currencyFull(paidTotal))),
                const SizedBox(width: 12),
                Expanded(child: _feeStatBox(Icons.calendar_today_rounded, AppColors.primary, 'NEXT DUE',
                    nextDue != null ? Formatters.currencyFull(nextDue.totalDue) : '—')),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ===== RECENT ATTENDANCE =====
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cardXlDecoration,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RECENT ATTENDANCE', style: AppTheme.headingSmall),
              const SizedBox(height: 16),
              if (attendance.records.isEmpty)
                Center(child: Text('NO ATTENDANCE DATA', style: AppTheme.labelSmall))
              else
                ...attendance.records.take(10).map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: r.isPresent ? AppColors.emerald50 : AppColors.red50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(r.isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 18, color: r.isPresent ? AppColors.emerald600 : AppColors.red500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(Formatters.date(r.createdAt), style: TextStyle(fontFamily: 'PlusJakartaSans', 
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700)),
                      Text(r.type, style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
                    ])),
                    StatusBadge(label: r.isPresent ? 'PRESENT' : 'ABSENT',
                        color: r.isPresent ? AppColors.emerald600 : AppColors.red500,
                        bgColor: r.isPresent ? AppColors.emerald50 : AppColors.red50),
                  ]),
                )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 16, color: AppColors.slate400)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.labelXs),
          Text(value.toUpperCase(), style: TextStyle(fontFamily: 'PlusJakartaSans', 
            fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
        ]),
      ]),
    );
  }

  Widget _transitRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 16, color: AppColors.primary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2,
            color: Colors.white.withOpacity(0.4))),
        const SizedBox(height: 2),
        Text(value.toUpperCase(), style: TextStyle(fontFamily: 'PlusJakartaSans', 
          fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
      ])),
    ]);
  }

  Widget _feeStatBox(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)]),
          child: Icon(icon, size: 18, color: color)),
        const SizedBox(height: 12),
        Text(label, style: AppTheme.labelXs),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate900)),
      ]),
    );
  }

  @override
  void dispose() { _childNameCtrl.dispose(); _childAdmCtrl.dispose(); _childGradeCtrl.dispose(); _childSectionCtrl.dispose(); super.dispose(); }
}
