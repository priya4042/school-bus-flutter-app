import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/bus_provider.dart';
import '../../../core/providers/fee_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/monthly_due_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';
  bool _showForm = false;
  Student? _editing;
  // Student form
  final _fk = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _admC = TextEditingController();
  final _gradeC = TextEditingController();
  final _secC = TextEditingController();
  final _boardC = TextEditingController();
  final _feeC = TextEditingController();
  final _parentPhoneC = TextEditingController();
  final _parentNameC = TextEditingController();
  String? _selRouteId, _selBusId;
  // Fee setup on create
  bool _generateFees = false;
  bool _yearlyMode = false;
  int _dueDayC = 10, _lastDayC = 20, _fineAfterC = 5;
  double _finePerDayC = 50;
  int _feeStartMonth = DateTime.now().month, _feeStartYear = DateTime.now().year;
  int _feeEndMonth = 12, _feeEndYear = DateTime.now().year;
  // View yearly fees
  Student? _viewingFees;
  // Fee Management tab - create fee
  bool _showFeeForm = false;
  String? _feeStudentId;
  final _feeAmtC = TextEditingController();
  int _feeMonth = DateTime.now().month, _feeYear = DateTime.now().year;
  final _feeDueDateC = TextEditingController();
  final _feeLastDateC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    context.read<StudentProvider>().fetchStudents();
    context.read<RouteProvider>().fetchRoutes();
    context.read<BusProvider>().fetchBuses();
    context.read<FeeProvider>().fetchDues();
  }

  void _reset() {
    _nameC.clear(); _admC.clear(); _gradeC.clear(); _secC.clear();
    _boardC.clear(); _feeC.clear(); _parentPhoneC.clear(); _parentNameC.clear();
    _selRouteId = null; _selBusId = null; _editing = null;
    _generateFees = false; _yearlyMode = false;
  }

  void _editStudent(Student s) {
    _nameC.text = s.fullName; _admC.text = s.admissionNumber;
    _gradeC.text = s.grade ?? ''; _secC.text = s.section ?? '';
    _boardC.text = s.boardingPoint ?? ''; _feeC.text = s.monthlyFee.toStringAsFixed(0);
    _parentPhoneC.text = s.parentPhone ?? ''; _parentNameC.text = s.parentName ?? '';
    _selRouteId = s.routeId; _selBusId = s.busId; _editing = s;
    setState(() => _showForm = true);
  }

  Future<void> _saveStudent() async {
    if (!_fk.currentState!.validate()) return;
    final prov = context.read<StudentProvider>();
    final data = <String, dynamic>{
      'full_name': _nameC.text.trim(),
      'admission_number': _admC.text.trim().toUpperCase(),
      'grade': _gradeC.text.trim(), 'section': _secC.text.trim(),
      'boarding_point': _boardC.text.trim(),
      'monthly_fee': double.tryParse(_feeC.text) ?? 0,
      'route_id': _selRouteId, 'bus_id': _selBusId, 'status': 'ACTIVE',
    };
    if (_parentPhoneC.text.isNotEmpty) data['parent_phone'] = _parentPhoneC.text.trim();
    if (_parentNameC.text.isNotEmpty) data['parent_name'] = _parentNameC.text.trim();

    bool ok;
    if (_editing != null) {
      ok = await prov.updateStudent(_editing!.id, data);
    } else {
      ok = await prov.addStudent(data);
      // Generate fees if checked
      if (ok && _generateFees) {
        final students = prov.students;
        final newStudent = students.isNotEmpty ? students.first : null;
        if (newStudent != null) {
          final feeProv = context.read<FeeProvider>();
          if (_yearlyMode) {
            await feeProv.createFeesForYear(
              studentId: newStudent.id,
              amount: double.tryParse(_feeC.text) ?? 0,
              year: _feeStartYear,
              startMonth: _feeStartMonth,
              endMonth: _feeEndMonth,
              dueDay: _dueDayC,
              finePerDay: _finePerDayC,
              fineAfterDays: _fineAfterC,
            );
          } else {
            await feeProv.createFee({
              'student_id': newStudent.id,
              'month': _feeStartMonth,
              'year': _feeStartYear,
              'amount': double.tryParse(_feeC.text) ?? 0,
              'due_date': DateTime(_feeStartYear, _feeStartMonth, _dueDayC).toIso8601String().split('T')[0],
              'last_date': DateTime(_feeStartYear, _feeStartMonth, _lastDayC).toIso8601String().split('T')[0],
              'fine_per_day': _finePerDayC,
              'fine_after_days': _fineAfterC,
            });
          }
        }
      }
    }
    if (ok && mounted) {
      setState(() => _showForm = false); _reset();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_editing != null ? 'STUDENT UPDATED' : 'STUDENT REGISTERED'),
        backgroundColor: AppColors.success));
    }
  }

  Future<void> _deleteStudent(Student s) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('DELETE ${s.fullName.toUpperCase()}?', style: AppTheme.headingSmall),
      content: Text('A snapshot will be saved in Reports for deleted students.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.slate500)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL', style: AppTheme.labelSmall.copyWith(color: AppColors.slate500))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text('DELETE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
      ],
    ));
    if (ok == true) {
      await context.read<StudentProvider>().deleteStudent(s.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('STUDENT ARCHIVED'), backgroundColor: AppColors.success));
    }
  }

  // ===== FEE MANAGEMENT: Mark Paid =====
  Future<void> _markPaid(MonthlyDue d) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('MARK AS PAID', style: AppTheme.headingSmall),
      content: Text('Mark ${d.fullMonthLabel} (${Formatters.currencyFull(d.totalDue)}) as paid?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFIRM')),
      ],
    ));
    if (ok == true) {
      final txn = 'MANUAL-${DateTime.now().millisecondsSinceEpoch}';
      await context.read<FeeProvider>().recordPayment(d.id, transactionId: txn, paymentMethod: 'CASH');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MARKED AS PAID'), backgroundColor: AppColors.success));
    }
  }

  // ===== FEE MANAGEMENT: Waive Late Fee =====
  Future<void> _waiveLateFee(MonthlyDue d) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('WAIVE LATE FEE', style: AppTheme.headingSmall),
      content: Text('Remove ${Formatters.currencyFull(d.lateFee)} late fee for ${d.fullMonthLabel}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('WAIVE')),
      ],
    ));
    if (ok == true) {
      await context.read<FeeProvider>().waiveLateFee(d.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('LATE FEE WAIVED'), backgroundColor: AppColors.success));
    }
  }

  // ===== FEE MANAGEMENT: Create Single Fee =====
  Future<void> _createSingleFee() async {
    if (_feeStudentId == null || _feeAmtC.text.isEmpty) return;
    final dueDate = _feeDueDateC.text.isNotEmpty ? _feeDueDateC.text : DateTime(_feeYear, _feeMonth, 10).toIso8601String().split('T')[0];
    final lastDate = _feeLastDateC.text.isNotEmpty ? _feeLastDateC.text : DateTime(_feeYear, _feeMonth, 20).toIso8601String().split('T')[0];
    await context.read<FeeProvider>().createFee({
      'student_id': _feeStudentId,
      'month': _feeMonth, 'year': _feeYear,
      'amount': double.tryParse(_feeAmtC.text) ?? 0,
      'due_date': dueDate, 'last_date': lastDate,
      'fine_per_day': _finePerDayC, 'fine_after_days': _fineAfterC,
    });
    if (mounted) {
      setState(() => _showFeeForm = false);
      _feeAmtC.clear(); _feeDueDateC.clear(); _feeLastDateC.clear();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FEE CREATED'), backgroundColor: AppColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tabs: Students / Fee Management
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200.withOpacity(0.5))),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
          indicatorSize: TabBarIndicatorSize.tab, dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
          labelColor: AppColors.primary, unselectedLabelColor: AppColors.slate400,
          tabs: const [Tab(text: 'STUDENTS'), Tab(text: 'FEE MANAGEMENT')],
        ),
      ),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _buildStudentsTab(),
        _buildFeeManagementTab(),
      ])),
    ]);
  }

  // ===== STUDENTS TAB =====
  Widget _buildStudentsTab() {
    final prov = context.watch<StudentProvider>();
    final routes = context.watch<RouteProvider>().routes;
    final buses = context.watch<BusProvider>().buses;
    final filtered = prov.students.where((s) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return s.fullName.toLowerCase().contains(q) || s.admissionNumber.toLowerCase().contains(q);
    }).toList();

    if (_showForm) return _buildStudentForm(routes, buses);
    if (_viewingFees != null) return _buildYearlyFeesView(_viewingFees!);

    return RefreshIndicator(
      onRefresh: () => prov.fetchStudents(),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
            decoration: AppTheme.inputDecoration('SEARCH STUDENTS', icon: Icons.search_rounded),
          )),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () { _reset(); setState(() => _showForm = true); },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.primaryButtonShadow()),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          Text('${filtered.length} STUDENTS', style: AppTheme.labelSmall.copyWith(color: AppColors.slate600)),
          const Spacer(),
          Text('${prov.activeStudents.length} ACTIVE', style: AppTheme.labelXs.copyWith(color: AppColors.success)),
        ])),
        const SizedBox(height: 8),
        Expanded(
          child: prov.isLoading
              ? const MiniLoader()
              : filtered.isEmpty
                  ? const EmptyState(icon: Icons.school_rounded, title: 'NO STUDENTS')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _studentCard(filtered[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _studentCard(Student s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100)),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.fullName.toUpperCase(), style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
          Text('${s.admissionNumber} • ${s.displayGrade}'.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
          if (s.routeName != null)
            Text('${s.routeName} • ${s.busNumber ?? ""}'.toUpperCase(), style: AppTheme.labelXs.copyWith(color: AppColors.primary)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.slate400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'fees', child: Row(children: [
              const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('VIEW FEES', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ])),
            PopupMenuItem(value: 'edit', child: Row(children: [
              const Icon(Icons.edit_rounded, size: 16, color: AppColors.slate500),
              const SizedBox(width: 8),
              Text('EDIT', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ])),
            PopupMenuItem(value: 'delete', child: Row(children: [
              const Icon(Icons.delete_rounded, size: 16, color: AppColors.danger),
              const SizedBox(width: 8),
              Text('DELETE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.danger)),
            ])),
          ],
          onSelected: (v) {
            if (v == 'fees') setState(() => _viewingFees = s);
            if (v == 'edit') _editStudent(s);
            if (v == 'delete') _deleteStudent(s);
          },
        ),
      ]),
    );
  }

  // ===== VIEW YEARLY FEES MODAL =====
  Widget _buildYearlyFeesView(Student s) {
    final fees = context.watch<FeeProvider>();
    final studentDues = fees.dues.where((d) => d.studentId == s.id).toList()
      ..sort((a, b) { final y = a.year.compareTo(b.year); return y != 0 ? y : a.month.compareTo(b.month); });
    final totalDue = studentDues.fold<double>(0, (sum, d) => sum + d.totalDue);
    final totalPaid = studentDues.where((d) => d.isPaid).fold<double>(0, (sum, d) => sum + d.totalDue);

    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(onPressed: () => setState(() => _viewingFees = null), icon: const Icon(Icons.arrow_back_rounded)),
        Expanded(child: Text('${s.fullName.toUpperCase()} — FEES', style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: AppColors.slate800))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _miniCard('TOTAL DUE', Formatters.currencyFull(totalDue), AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('PAID', Formatters.currencyFull(totalPaid), AppColors.success)),
        const SizedBox(width: 8),
        Expanded(child: _miniCard('PENDING', Formatters.currencyFull(totalDue - totalPaid), AppColors.danger)),
      ]),
      const SizedBox(height: 16),
      ...studentDues.map((d) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.slate100)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.fullMonthLabel.toUpperCase(), style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            const SizedBox(height: 4),
            StatusBadge.fromStatus(d.isPaid ? 'PAID' : d.isOverdue ? 'OVERDUE' : 'PENDING'),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.currencyFull(d.totalDue), style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            if (d.lateFee > 0) Text('LATE: ${Formatters.currencyFull(d.lateFee)}',
                style: AppTheme.labelXs.copyWith(color: AppColors.danger)),
            if (d.isPaid && d.paidAt != null) Text(Formatters.date(d.paidAt!),
                style: AppTheme.labelXs.copyWith(color: AppColors.success)),
          ]),
          if (!d.isPaid) PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.slate400),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pay', child: Text('MARK AS PAID')),
              if (d.lateFee > 0) const PopupMenuItem(value: 'waive', child: Text('WAIVE LATE FEE')),
            ],
            onSelected: (v) {
              if (v == 'pay') _markPaid(d);
              if (v == 'waive') _waiveLateFee(d);
            },
          ),
        ]),
      )),
    ]));
  }

  Widget _miniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.1))),
      child: Column(children: [
        Text(label, style: AppTheme.labelXs), const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  // ===== STUDENT FORM (Create/Edit with Fee Setup) =====
  Widget _buildStudentForm(List routes, List buses) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _fk, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(onPressed: () => setState(() { _showForm = false; _reset(); }), icon: const Icon(Icons.arrow_back_rounded)),
          Text(_editing != null ? 'EDIT STUDENT' : 'REGISTER STUDENT', style: AppTheme.headingSmall),
        ]),
        const SizedBox(height: 12),
        // Academic Profile section
        _sectionLabel('ACADEMIC PROFILE', AppColors.primary),
        _f('STUDENT NAME', _nameC, true), _f('ADMISSION NUMBER', _admC, true),
        Row(children: [
          Expanded(child: _f('GRADE', _gradeC, true)),
          const SizedBox(width: 12),
          Expanded(child: _f('SECTION', _secC, true)),
        ]),
        _f('MONTHLY FEE (₹)', _feeC, true, TextInputType.number),
        const SizedBox(height: 8),
        // Fleet Mapping section
        _sectionLabel('FLEET MAPPING', AppColors.success),
        _f('PARENT NAME', _parentNameC, false), _f('PARENT PHONE', _parentPhoneC, false, TextInputType.phone),
        _dropdown('ASSIGNED ROUTE', _selRouteId, routes.map((r) => DropdownMenuItem<String>(value: r.id, child: Text(r.routeName))).toList(),
            (v) => setState(() => _selRouteId = v)),
        _dropdown('ASSIGNED BUS', _selBusId, buses.map((b) => DropdownMenuItem<String>(value: b.id, child: Text('${b.busNumber} (${b.vehicleNumber})'))).toList(),
            (v) => setState(() => _selBusId = v)),
        _f('BOARDING POINT', _boardC, false),
        const SizedBox(height: 8),
        // Initial Fee Setup (only on create)
        if (_editing == null) ...[
          _sectionLabel('INITIAL FEE SETUP', AppColors.indigo600),
          SwitchListTile(
            value: _generateFees,
            onChanged: (v) => setState(() => _generateFees = v),
            title: Text('GENERATE FEE RECORDS', style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.slate700)),
            subtitle: Text('CREATE BILLING DURING REGISTRATION', style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
            contentPadding: EdgeInsets.zero,
          ),
          if (_generateFees) ...[
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _yearlyMode = false),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: !_yearlyMode ? AppColors.primary : AppColors.slate100, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('MONTHLY', style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: !_yearlyMode ? Colors.white : AppColors.slate500)))),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _yearlyMode = true),
                child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: _yearlyMode ? AppColors.primary : AppColors.slate100, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('FINANCIAL YEAR', style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: _yearlyMode ? Colors.white : AppColors.slate500)))),
              )),
            ]),
            const SizedBox(height: 12),
            if (_yearlyMode) ...[
              Row(children: [
                Expanded(child: _numField('START MONTH', _feeStartMonth, (v) => setState(() => _feeStartMonth = v))),
                const SizedBox(width: 8),
                Expanded(child: _numField('END MONTH', _feeEndMonth, (v) => setState(() => _feeEndMonth = v))),
              ]),
            ],
            Row(children: [
              Expanded(child: _numField('DUE DAY', _dueDayC, (v) => setState(() => _dueDayC = v))),
              const SizedBox(width: 8),
              Expanded(child: _numField('FINE AFTER DAYS', _fineAfterC, (v) => setState(() => _fineAfterC = v))),
              const SizedBox(width: 8),
              Expanded(child: _numField('FINE/DAY (₹)', _finePerDayC.toInt(), (v) => setState(() => _finePerDayC = v.toDouble()))),
            ]),
          ],
        ],
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.primaryButtonShadow()),
          child: ElevatedButton(onPressed: _saveStudent, style: AppTheme.primaryButton,
            child: Text(_editing != null ? 'UPDATE STUDENT' : 'REGISTER STUDENT',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
        )),
      ],
    )));
  }

  // ===== FEE MANAGEMENT TAB =====
  Widget _buildFeeManagementTab() {
    final fees = context.watch<FeeProvider>();
    final students = context.watch<StudentProvider>().students;
    // Group dues by student
    final byStudent = <String, List<MonthlyDue>>{};
    for (final d in fees.dues) {
      byStudent.putIfAbsent(d.studentId, () => []).add(d);
    }

    if (_showFeeForm) {
      return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(onPressed: () => setState(() => _showFeeForm = false), icon: const Icon(Icons.arrow_back_rounded)),
          Text('CREATE FEE', style: AppTheme.headingSmall),
        ]),
        const SizedBox(height: 16),
        _dropdown('STUDENT', _feeStudentId, students.map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.fullName))).toList(),
            (v) => setState(() => _feeStudentId = v)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _numField('MONTH', _feeMonth, (v) => setState(() => _feeMonth = v))),
          const SizedBox(width: 8),
          Expanded(child: _numField('YEAR', _feeYear, (v) => setState(() => _feeYear = v))),
        ]),
        const SizedBox(height: 12),
        _f('AMOUNT (₹)', _feeAmtC, true, TextInputType.number),
        _f('DUE DATE', _feeDueDateC, false),
        _f('LAST DATE', _feeLastDateC, false),
        const SizedBox(height: 8),
        // Fine preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FINE PREVIEW', style: AppTheme.labelSmall.copyWith(color: AppColors.amber600)),
            const SizedBox(height: 8),
            Text('Day 1: ₹0  •  Day ${_fineAfterC + 1}: ₹${_finePerDayC.toInt()}  •  Day ${_fineAfterC + 7}: ₹${(_finePerDayC * 7).toInt()}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber600)),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _createSingleFee, style: AppTheme.primaryButton,
          child: Text('CREATE FEE', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)))),
      ]));
    }

    return RefreshIndicator(
      onRefresh: () => fees.fetchDues(),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Text('${byStudent.length} STUDENTS WITH FEES', style: AppTheme.labelSmall.copyWith(color: AppColors.slate600)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showFeeForm = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.primaryButtonShadow()),
              child: Text('+ CREATE FEE', style: GoogleFonts.plusJakartaSans(
                fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
            ),
          ),
        ])),
        Expanded(
          child: fees.isLoading ? const MiniLoader() : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: byStudent.length,
            itemBuilder: (_, i) {
              final entry = byStudent.entries.elementAt(i);
              final dues = entry.value;
              final student = students.where((s) => s.id == entry.key).firstOrNull;
              final totalDue = dues.fold<double>(0, (s, d) => s + d.totalDue);
              final totalPaid = dues.where((d) => d.isPaid).fold<double>(0, (s, d) => s + d.totalDue);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.slate100)),
                child: ExpansionTile(
                  leading: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text((student?.fullName ?? 'S')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
                  title: Text(student?.fullName.toUpperCase() ?? 'UNKNOWN', style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                  subtitle: Row(children: [
                    Text('DUE: ${Formatters.currencyFull(totalDue)}', style: AppTheme.labelXs.copyWith(color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Text('PAID: ${Formatters.currencyFull(totalPaid)}', style: AppTheme.labelXs.copyWith(color: AppColors.success)),
                  ]),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: dues.map((d) => Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.monthLabel.toUpperCase(), style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate700)),
                        StatusBadge.fromStatus(d.isPaid ? 'PAID' : d.isOverdue ? 'OVERDUE' : 'PENDING'),
                      ])),
                      Text(Formatters.currencyFull(d.totalDue), style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                      if (!d.isPaid) PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.slate400),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'pay', child: Text('MARK PAID')),
                          if (d.lateFee > 0) const PopupMenuItem(value: 'waive', child: Text('WAIVE LATE FEE')),
                          const PopupMenuItem(value: 'notify', child: Text('SEND REMINDER')),
                        ],
                        onSelected: (v) {
                          if (v == 'pay') _markPaid(d);
                          if (v == 'waive') _waiveLateFee(d);
                        },
                      ),
                    ]),
                  )).toList(),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // Helpers
  Widget _sectionLabel(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: color.withOpacity(0.1)))),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3, color: color)),
    ),
  );

  Widget _f(String l, TextEditingController c, bool req, [TextInputType t = TextInputType.text]) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(controller: c, keyboardType: t,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
      decoration: AppTheme.inputDecoration(l),
      validator: req ? (v) => v?.isEmpty ?? true ? 'Required' : null : null),
  );

  Widget _dropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: value, decoration: AppTheme.inputDecoration(label),
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
      items: [DropdownMenuItem(value: null, child: Text('SELECT...', style: GoogleFonts.plusJakartaSans(color: AppColors.slate400))), ...items],
      onChanged: onChanged),
  );

  Widget _numField(String label, int value, Function(int) onChanged) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTheme.labelXs),
      Row(children: [
        IconButton(icon: const Icon(Icons.remove_rounded, size: 16), onPressed: () => onChanged(value - 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('$value', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.slate800))),
        IconButton(icon: const Icon(Icons.add_rounded, size: 16), onPressed: () => onChanged(value + 1), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
      ]),
    ]),
  );

  @override
  void dispose() {
    _tabCtrl.dispose(); _nameC.dispose(); _admC.dispose(); _gradeC.dispose(); _secC.dispose();
    _boardC.dispose(); _feeC.dispose(); _parentPhoneC.dispose(); _parentNameC.dispose();
    _feeAmtC.dispose(); _feeDueDateC.dispose(); _feeLastDateC.dispose();
    super.dispose();
  }
}
