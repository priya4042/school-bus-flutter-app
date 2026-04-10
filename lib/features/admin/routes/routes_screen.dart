import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/models/route_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../../shared/widgets/stat_card.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  bool _showForm = false;
  BusRoute? _editing;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _distCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RouteProvider>().fetchRoutes();
  }

  void _resetForm() {
    _nameCtrl.clear(); _codeCtrl.clear(); _feeCtrl.clear();
    _distCtrl.clear(); _startCtrl.clear(); _endCtrl.clear();
    _editing = null;
  }

  void _edit(BusRoute r) {
    _nameCtrl.text = r.routeName; _codeCtrl.text = r.code;
    _feeCtrl.text = r.baseFee?.toStringAsFixed(0) ?? '';
    _distCtrl.text = r.distanceKm?.toStringAsFixed(1) ?? '';
    _startCtrl.text = r.startPoint ?? ''; _endCtrl.text = r.endPoint ?? '';
    _editing = r;
    setState(() => _showForm = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<RouteProvider>();
    final data = {
      'route_name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim().toUpperCase(),
      'base_fee': double.tryParse(_feeCtrl.text),
      'distance_km': double.tryParse(_distCtrl.text),
      'start_point': _startCtrl.text.trim(),
      'end_point': _endCtrl.text.trim(),
    };
    final ok = _editing != null
        ? await prov.updateRoute(_editing!.id, data)
        : await prov.addRoute(data);
    if (ok && mounted) { setState(() => _showForm = false); _resetForm(); }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RouteProvider>();

    if (_showForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(key: _formKey, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(onPressed: () => setState(() { _showForm = false; _resetForm(); }), icon: const Icon(Icons.arrow_back)),
              Text(_editing != null ? 'Edit Route' : 'Add Route', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            _f('Route Name', _nameCtrl, true),
            _f('Code', _codeCtrl, true),
            Row(children: [
              Expanded(child: _f('Base Fee (₹)', _feeCtrl, false, TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _f('Distance (km)', _distCtrl, false, TextInputType.number)),
            ]),
            _f('Start Point', _startCtrl, false),
            _f('End Point', _endCtrl, false),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, height: 52,
              child: ElevatedButton(onPressed: _save, child: Text(_editing != null ? 'Update' : 'Add Route'))),
          ],
        )),
      );
    }

    return RefreshIndicator(
      onRefresh: () => prov.fetchRoutes(),
      child: prov.isLoading
          ? const MiniLoader()
          : prov.routes.isEmpty
              ? const EmptyState(icon: Icons.route_outlined, title: 'No routes yet')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.routes.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Text('${prov.routes.length} Routes', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const Spacer(),
                          FloatingActionButton.small(
                            onPressed: () { _resetForm(); setState(() => _showForm = true); },
                            child: const Icon(Icons.add),
                          ),
                        ]),
                      );
                    }
                    final r = prov.routes[i - 1];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(r.code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r.routeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                            PopupMenuButton(itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                            ], onSelected: (v) {
                              if (v == 'edit') _edit(r);
                              if (v == 'delete') prov.deleteRoute(r.id);
                            }),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(r.startPoint ?? 'N/A', style: const TextStyle(fontSize: 13)),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary)),
                            const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text(r.endPoint ?? 'N/A', style: const TextStyle(fontSize: 13)),
                          ]),
                          if (r.baseFee != null || r.distanceKm != null) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              if (r.baseFee != null) Text('Fee: ${Formatters.currencyFull(r.baseFee!)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              if (r.baseFee != null && r.distanceKm != null) const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                              if (r.distanceKm != null) Text('${r.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ]),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _f(String l, TextEditingController c, bool req, [TextInputType t = TextInputType.text]) {
    return Padding(padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(controller: c, keyboardType: t, decoration: InputDecoration(labelText: l),
        validator: req ? (v) => v == null || v.isEmpty ? 'Required' : null : null));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _codeCtrl.dispose(); _feeCtrl.dispose();
    _distCtrl.dispose(); _startCtrl.dispose(); _endCtrl.dispose();
    super.dispose();
  }
}
