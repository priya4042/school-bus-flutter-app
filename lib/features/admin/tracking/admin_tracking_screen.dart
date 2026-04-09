import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/bus_provider.dart';
import '../../../core/models/bus_model.dart';
import '../../../core/theme/app_theme.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  final _mapCtrl = MapController();
  Bus? _selectedBus;
  LatLng? _busLocation;
  double _speed = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    context.read<BusProvider>().fetchBuses();
  }

  void _selectBus(Bus bus) {
    _sub?.cancel();
    setState(() {
      _selectedBus = bus;
      _busLocation = null;
    });

    // Fetch last known location
    Supabase.instance.client
        .from('bus_locations')
        .select()
        .eq('bus_id', bus.id)
        .order('updated_at', ascending: false)
        .limit(1)
        .then((res) {
      if (res is List && res.isNotEmpty) {
        final loc = res[0];
        setState(() {
          _busLocation = LatLng(
            (loc['latitude'] as num).toDouble(),
            (loc['longitude'] as num).toDouble(),
          );
          _speed = (loc['speed'] as num?)?.toDouble() ?? 0;
        });
        _mapCtrl.move(_busLocation!, 15);
      }
    });

    // Subscribe to realtime
    _sub = Supabase.instance.client
        .from('bus_locations')
        .stream(primaryKey: ['id'])
        .eq('bus_id', bus.id)
        .listen((data) {
      if (data.isNotEmpty) {
        final loc = data.first;
        setState(() {
          _busLocation = LatLng(
            (loc['latitude'] as num).toDouble(),
            (loc['longitude'] as num).toDouble(),
          );
          _speed = (loc['speed'] as num?)?.toDouble() ?? 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final buses = context.watch<BusProvider>().buses;

    return Column(children: [
      // Bus selector
      SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: buses.length,
          itemBuilder: (_, i) {
            final b = buses[i];
            final selected = _selectedBus?.id == b.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(b.busNumber),
                selected: selected,
                onSelected: (_) => _selectBus(b),
                avatar: Icon(Icons.directions_bus, size: 18,
                    color: selected ? Colors.white : AppColors.textSecondary),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
              ),
            );
          },
        ),
      ),

      // Map
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
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
            ],
          ),

          // Speed overlay
          if (_selectedBus != null)
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  const Icon(Icons.directions_bus, color: Colors.white),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_selectedBus!.busNumber,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text(_selectedBus!.vehicleNumber,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ]),
                  const Spacer(),
                  Column(children: [
                    Text('${_speed.toStringAsFixed(0)} km/h',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    Text('Speed', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                  ]),
                ]),
              ),
            ),

          if (_selectedBus == null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.gps_fixed, size: 40, color: AppColors.textSecondary),
                  SizedBox(height: 8),
                  Text('Select a bus to track', style: TextStyle(fontWeight: FontWeight.w600)),
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
