import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

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
  void initState() { super.initState(); _load(); }

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

    Supabase.instance.client.from('bus_locations').select()
        .eq('bus_id', child.busId!).order('updated_at', ascending: false).limit(1)
        .then((res) { if (res is List && res.isNotEmpty) _updateLoc(res[0]); });

    _sub = Supabase.instance.client.from('bus_locations').stream(primaryKey: ['id'])
        .eq('bus_id', child.busId!).listen((data) { if (data.isNotEmpty) _updateLoc(data.first); });
  }

  void _updateLoc(Map<String, dynamic> loc) {
    if (!mounted) return;
    setState(() {
      _busLocation = LatLng((loc['latitude'] as num).toDouble(), (loc['longitude'] as num).toDouble());
      _speed = (loc['speed'] as num?)?.toDouble() ?? 0;
    });
    _mapCtrl.move(_busLocation!, 15);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final students = context.watch<StudentProvider>().students;

    // Permission gate
    final hasTracking = auth.user?.preferences.tracking != false;
    if (!hasTracking) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.gps_off_rounded, size: 36, color: AppColors.slate300)),
          const SizedBox(height: 16),
          Text('TRACKING ACCESS NOT ENABLED', style: AppTheme.labelStyle.copyWith(color: AppColors.slate600)),
          const SizedBox(height: 8),
          Text('Contact admin to enable live tracking', style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: AppColors.slate400)),
        ],
      )));
    }

    return Column(children: [
      if (students.length > 1)
        SizedBox(height: 50, child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: students.length,
          itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () { setState(() => _selectedChild = i); _trackBus(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: i == _selectedChild ? AppColors.primary : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(students[i].fullName.split(' ').first.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2,
                      color: i == _selectedChild ? Colors.white : AppColors.slate500))),
              ),
            ),
          ),
        )),
      Expanded(child: Stack(children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _busLocation ?? const LatLng(20.5937, 78.9629),
            initialZoom: _busLocation != null ? 15 : 5),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.buswaypro.app'),
            if (_busLocation != null) MarkerLayer(markers: [
              Marker(point: _busLocation!, width: 44, height: 44,
                child: Container(
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)]),
                  child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 20))),
            ]),
          ],
        ),

        // Status badges
        if (_busLocation != null && students.isNotEmpty)
          Positioned(top: 12, left: 12, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
            ]),
          )),

        // Bottom info card
        if (students.isNotEmpty)
          Positioned(bottom: 16, left: 16, right: 16, child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16)],
                border: Border.all(color: AppColors.slate100)),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(students[_selectedChild.clamp(0, students.length - 1)].fullName.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppColors.slate800)),
                Text(students[_selectedChild.clamp(0, students.length - 1)].busNumber?.toUpperCase() ?? 'NO BUS',
                    style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
              ]),
              const Spacer(),
              if (_busLocation != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.speed_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text('${_speed.toStringAsFixed(0)} KM/H', style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.success)),
                  ]),
                )
              else
                Text('NO GPS DATA', style: AppTheme.labelXs.copyWith(color: AppColors.slate400)),
            ]),
          )),

        // Camera badge
        if (auth.user?.preferences.camera == true)
          Positioned(top: 12, right: 12, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.slate200)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.videocam_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text('CAMERA', style: GoogleFonts.plusJakartaSans(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.primary)),
            ]),
          )),
      ])),
    ]);
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
