import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/providers/bus_provider.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _search = '';
  bool _showForm = false;
  Student? _editing;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _admissionCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _boardingCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  String? _selectedRouteId;
  String? _selectedBusId;

  @override
  void initState() {
    super.initState();
    context.read<StudentProvider>().fetchStudents();
    context.read<RouteProvider>().fetchRoutes();
    context.read<BusProvider>().fetchBuses();
  }

  void _resetForm() {
    _nameCtrl.clear();
    _admissionCtrl.clear();
    _gradeCtrl.clear();
    _sectionCtrl.clear();
    _boardingCtrl.clear();
    _feeCtrl.clear();
    _parentPhoneCtrl.clear();
    _selectedRouteId = null;
    _selectedBusId = null;
    _editing = null;
  }

  void _editStudent(Student s) {
    _nameCtrl.text = s.fullName;
    _admissionCtrl.text = s.admissionNumber;
    _gradeCtrl.text = s.grade ?? '';
    _sectionCtrl.text = s.section ?? '';
    _boardingCtrl.text = s.boardingPoint ?? '';
    _feeCtrl.text = s.monthlyFee.toStringAsFixed(0);
    _selectedRouteId = s.routeId;
    _selectedBusId = s.busId;
    _editing = s;
    setState(() => _showForm = true);
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<StudentProvider>();
    final data = {
      'full_name': _nameCtrl.text.trim(),
      'admission_number': _admissionCtrl.text.trim().toUpperCase(),
      'grade': _gradeCtrl.text.trim(),
      'section': _sectionCtrl.text.trim(),
      'boarding_point': _boardingCtrl.text.trim(),
      'monthly_fee': double.tryParse(_feeCtrl.text) ?? 0,
      'route_id': _selectedRouteId,
      'bus_id': _selectedBusId,
      'status': 'ACTIVE',
    };

    if (_parentPhoneCtrl.text.isNotEmpty) {
      data['parent_phone'] = _parentPhoneCtrl.text.trim();
    }

    bool success;
    if (_editing != null) {
      success = await prov.updateStudent(_editing!.id, data);
    } else {
      success = await prov.addStudent(data);
    }

    if (success && mounted) {
      setState(() => _showForm = false);
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing != null ? 'Student updated' : 'Student added'),
            backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _deleteStudent(Student s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${s.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<StudentProvider>().deleteStudent(s.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final routes = context.watch<RouteProvider>().routes;
    final buses = context.watch<BusProvider>().buses;

    final filtered = prov.students.where((s) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.admissionNumber.toLowerCase().contains(q) ||
          (s.parentName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => prov.fetchStudents(),
      child: _showForm
          ? _buildForm(routes, buses)
          : _buildList(filtered, prov),
    );
  }

  Widget _buildList(List<Student> filtered, StudentProvider prov) {
    return Column(
      children: [
        // Search + Add
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                onPressed: () {
                  _resetForm();
                  setState(() => _showForm = true);
                },
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${filtered.length} students',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${prov.activeStudents.length} active',
                  style: const TextStyle(color: AppColors.success, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const EmptyState(icon: Icons.people_outlined, title: 'No students found')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _studentCard(filtered[i]),
                    ),
        ),
      ],
    );
  }

  Widget _studentCard(Student s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text(s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.admissionNumber} • ${s.displayGrade}',
                style: const TextStyle(fontSize: 13)),
            if (s.routeName != null)
              Text('Route: ${s.routeName}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete',
                style: TextStyle(color: AppColors.error))),
          ],
          onSelected: (v) {
            if (v == 'edit') _editStudent(s);
            if (v == 'delete') _deleteStudent(s);
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildForm(List routes, List buses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() { _showForm = false; _resetForm(); }),
                  icon: const Icon(Icons.arrow_back),
                ),
                Text(_editing != null ? 'Edit Student' : 'Add Student',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            _field('Full Name', _nameCtrl, required: true),
            _field('Admission Number', _admissionCtrl, required: true),
            Row(children: [
              Expanded(child: _field('Grade', _gradeCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _field('Section', _sectionCtrl)),
            ]),
            _field('Monthly Fee (₹)', _feeCtrl, inputType: TextInputType.number),
            _field('Boarding Point', _boardingCtrl),
            _field('Parent Phone', _parentPhoneCtrl, inputType: TextInputType.phone),

            // Route Dropdown
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRouteId,
              decoration: const InputDecoration(labelText: 'Route'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Route')),
                ...routes.map((r) => DropdownMenuItem(
                    value: r.id, child: Text(r.routeName))),
              ],
              onChanged: (v) => setState(() => _selectedRouteId = v),
            ),
            const SizedBox(height: 16),

            // Bus Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBusId,
              decoration: const InputDecoration(labelText: 'Bus'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Bus')),
                ...buses.map((b) => DropdownMenuItem(
                    value: b.id, child: Text('${b.busNumber} (${b.vehicleNumber})'))),
              ],
              onChanged: (v) => setState(() => _selectedBusId = v),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveStudent,
                child: Text(_editing != null ? 'Update Student' : 'Add Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _admissionCtrl.dispose();
    _gradeCtrl.dispose();
    _sectionCtrl.dispose();
    _boardingCtrl.dispose();
    _feeCtrl.dispose();
    _parentPhoneCtrl.dispose();
    super.dispose();
  }
}
