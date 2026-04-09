import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unread => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unread.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabase = Supabase.instance.client;

  Future<void> fetchNotifications(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(120);

      _notifications = (res as List).map((e) => AppNotification.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void subscribe(String userId) {
    _subscription?.cancel();
    _subscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((data) {
      _notifications = data.map((e) => AppNotification.fromMap(e)).toList();
      notifyListeners();
    });
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        final n = _notifications[idx];
        _notifications[idx] = AppNotification(
          id: n.id, userId: n.userId, title: n.title,
          message: n.message, type: n.type, isRead: true,
          createdAt: n.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id, userId: n.userId, title: n.title,
        message: n.message, type: n.type, isRead: true,
        createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'INFO',
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> broadcastToParents({
    required String title,
    required String message,
    required String type,
    List<String>? parentIds,
  }) async {
    try {
      List<String> targets;
      if (parentIds != null && parentIds.isNotEmpty) {
        targets = parentIds;
      } else {
        final res = await _supabase
            .from('profiles')
            .select('id')
            .eq('role', 'PARENT');
        targets = (res as List).map((e) => e['id'] as String).toList();
      }

      final batch = targets.map((id) => {
        'user_id': id,
        'title': title,
        'message': message,
        'type': type,
      }).toList();

      if (batch.isNotEmpty) {
        await _supabase.from('notifications').insert(batch);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
