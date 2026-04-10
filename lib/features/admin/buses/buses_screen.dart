import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/bus_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/models/bus_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class BusesScreen extends StatefulWidget {
  const BusesScreen({super.key});

  @override
  State<BusesScreen> createState() => _BusesScreenState();
}

class _BusesScreenState extends State<BusesScreen> {
  String _search = '';
  bool _showForm = false;
  Bus? _editing;

  final _formKey = GlobalKey<FormState>();
  final _busNumCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '40');
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  String? _selectedRouteId;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().fetchBuses();
    context.read<RouteProvider>().fetchRoutes();
  }

  void _resetForm() {
    _busNumCtrl.clear();
    _plateCtrl.clear();
    _modelCtrl.clear();
    _capacityCtrl.text = '40';
    _driverNameCtrl.clear();
    _driverPhoneCtrl.clear();
    _selectedRouteId = null;
    _editing = null;
  }

  void _editBus(Bus b) {
    _busNumCtrl.text = b.busNumber;
    _plateCtrl.text = b.vehicleNumber;
    _modelCtrl.text = b.model ?? '';
    _capacityCtrl.text = b.capacity.toString();
    _driverNameCtrl.text = b.driverName ?? '';
    _driverPhoneCtrl.text = b.driverPhone ?? '';
    _selectedRouteId = b.routeId;
    _editing = b;
    setState(() => _showForm = true);
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<BusProvider>();
    final data = {
      'bus_number': _busNumCtrl.text.trim(),
      'vehicle_number': _plateCtrl.text.trim(),
      'model': _modelCtrl.text.trim(),
      'capacity': int.tryParse(_capacityCtrl.text) ?? 40,
      'driver_name': _driverNameCtrl.text.trim(),
      'driver_phone': _driverPhoneCtrl.text.trim(),
      'route_id': _selectedRouteId,
    };

    final success = _editing != null
        ? await prov.updateBus(_editing!.id, data)
        : await prov.addBus(data);

    if (success && mounted) {
      setState(() => _showForm = false);
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BusProvider>();
    final routes = context.watch<RouteProvider>().routes;
    final filtered = prov.buses.where((b) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return b.busNumber.toLowerCase().contains(q) ||
          b.vehicleNumber.toLowerCase().contains(q) ||
          (b.driverName?.toLowerCase().contains(q) ?? false);
    }).toList();

    if (_showForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                IconButton(onPressed: () => setState(() { _showForm = false; _resetForm(); }),
                    icon: const Icon(Icons.arrow_back)),
                Text(_editing != null ? 'Edit Bus' : 'Register Bus',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 16),
              _field('Bus Number', _busNumCtrl, required: true),
              _field('Vehicle Plate', _plateCtrl, required: true),
              _field('Model', _modelCtrl),
              _field('Capacity', _capacityCtrl, inputType: TextInputType.number),
              _field('Driver Name', _driverNameCtrl),
              _field('Driver Phone', _driverPhoneCtrl, inputType: TextInputType.phone),
              DropdownButtonFormField<String>(
                value: _selectedRouteId,
                decoration: const InputDecoration(labelText: 'Route'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Route')),
                  ...routes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.routeName))),
                ],
                onChanged: (v) => setState(() => _selectedRouteId = v),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(onPressed: _saveBus,
                    child: Text(_editing != null ? 'Update Bus' : 'Register Bus'))),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchBuses(),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(hintText: 'Search buses...', prefixIcon: Icon(Icons.search), isDense: true),
            )),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              onPressed: () { _resetForm(); setState(() => _showForm = true); },
              child: const Icon(Icons.add),
            ),
          ]),
        ),
        Expanded(
          child: prov.isLoading
              ? const MiniLoader()
              : filtered.isEmpty
                  ? const EmptyState(icon: Icons.directions_bus_outlined, title: 'No buses found')
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final b = filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: b.isActive ? AppColors.success.withOpacity(0.1) : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.directions_bus,
                                  color: b.isActive ? AppColors.success : AppColors.textSecondary),
                            ),
                            title: Text(b.busNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${b.vehicleNumber} • ${b.routeName ?? "No route"}'),
                            trailing: PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                              ],
                              onSelected: (v) {
                                if (v == 'edit') _editBus(b);
                                if (v == 'delete') prov.deleteBus(b.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(controller: ctrl, keyboardType: inputType,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null),
    );
  }

  @override
  void dispose() {
    _busNumCtrl.dispose(); _plateCtrl.dispose(); _modelCtrl.dispose();
    _capacityCtrl.dispose(); _driverNameCtrl.dispose(); _driverPhoneCtrl.dispose();
    super.dispose();
  }
}
