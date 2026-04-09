import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route_model.dart';

class RouteProvider extends ChangeNotifier {
  List<BusRoute> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<BusRoute> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabase = Supabase.instance.client;

  Future<void> fetchRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('routes')
          .select()
          .order('route_name');

      _routes = (res as List).map((e) => BusRoute.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addRoute(Map<String, dynamic> data) async {
    try {
      await _supabase.from('routes').insert(data);
      await fetchRoutes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRoute(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('routes').update(data).eq('id', id);
      await fetchRoutes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRoute(String id) async {
    try {
      await _supabase.from('routes').delete().eq('id', id);
      await fetchRoutes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
