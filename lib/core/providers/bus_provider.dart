import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus_model.dart';

class BusProvider extends ChangeNotifier {
  List<Bus> _buses = [];
  bool _isLoading = false;
  String? _error;

  List<Bus> get buses => _buses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Bus> get activeBuses => _buses.where((b) => b.isActive).toList();

  final _supabase = Supabase.instance.client;

  Future<void> fetchBuses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('buses')
          .select('*, routes(route_name)')
          .order('bus_number');

      _buses = (res as List).map((e) => Bus.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBus(Map<String, dynamic> data) async {
    try {
      await _supabase.from('buses').insert(data);
      await fetchBuses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBus(String id, Map<String, dynamic> data) async {
    try {
      data.remove('routes');
      await _supabase.from('buses').update(data).eq('id', id);
      await fetchBuses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBus(String id) async {
    try {
      await _supabase.from('buses').delete().eq('id', id);
      await fetchBuses();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
