import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_theme.dart';

class ParentTrackingScreen extends StatefulWidget {
  const ParentTrackingScreen({super.key});

  @override
  State<ParentTrackingScreen> createState() => _ParentTrackingScreenState();
}

class _ParentTrackingScreenState extends State<ParentTrackingScreen> {
  final _mapCtrl = MapController();
  int _selectedChild = 0;
  LatLng? _busLocation;
  double _speed = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AppAuthProvider>();
    if (auth.user == null) return;
    await context.read<StudentProvider>().fetchParentStudents(auth.user!.id);
    _trackBus();
  }

  void _trackBus() {
    _sub?.cancel();
    final students = context.read<StudentProvider>().students;
    if (students.isEmpty) return;
    final child = students[_selectedChild.clamp(0, students.length - 1)];
    if (child.busId == null) return;

    // Fetch last known
    Supabase.instance.client
        .from('bus_locations')
        .select()
        .eq('bus_id', child.busId!)
        .order('updated_at', ascending: false)
        .limit(1)
        .then((res) {
      if (res is List && res.isNotEmpty) {
        _updateLocation(res[0]);
      }
    });

    // Subscribe realtime
    _sub = Supabase.instance.client
        .from('bus_locations')
        .stream(primaryKey: ['id'])
        .eq('bus_id', child.busId!)
        .listen((data) {
      if (data.isNotEmpty) _updateLocation(data.first);
    });
  }

  void _updateLocation(Map<String, dynamic> loc) {
    if (!mounted) return;
    setState(() {
      _busLocation = LatLng(
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
      _speed = (loc['speed'] as num?)?.toDouble() ?? 0;
    });
    _mapCtrl.move(_busLocation!, 15);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;

    return Column(children: [
      // Child selector
      if (students.length > 1)
        SizedBox(height: 50, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: students.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(students[i].fullName),
              selected: i == _selectedChild,
              onSelected: (_) { setState(() => _selectedChild = i); _trackBus(); },
            ),
          ),
        )),

      Expanded(
        child: Stack(children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _busLocation ?? const LatLng(20.5937, 78.9629),
              initialZoom: _busLocation != null ? 15 : 5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.buswaypro.app',
              ),
              if (_busLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _busLocation!,
                    width: 40, height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
            ],
          ),

          // Info overlay
          if (students.isNotEmpty)
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(students[_selectedChild.clamp(0, students.length - 1)].fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(students[_selectedChild.clamp(0, students.length - 1)].busNumber ?? 'No bus',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ]),
                  const Spacer(),
                  if (_busLocation != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.speed, size: 16, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text('${_speed.toStringAsFixed(0)} km/h',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success)),
                      ]),
                    ),
                  ] else
                    const Text('No GPS data', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
            ),
        ]),
      ),
    ]);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
