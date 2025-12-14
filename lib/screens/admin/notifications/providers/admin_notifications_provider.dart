import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class AdminNotificationsProvider extends ChangeNotifier {
  final Dio _dio;
  
  AdminNotificationsProvider(this._dio);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _requests = [];
  List<dynamic> get requests => _requests;

  int get unresolvedCount => _requests.where((r) => r['is_resolved'] == false).length;

  Future<void> fetchRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _dio.get('/admin/notifications/pending-resets');
      if (res.data is List) {
        _requests = List.from(res.data);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsResolved(int id) async {
    try {
      await _dio.post('/admin/notifications/pending-resets/$id/resolve');
      // Optimistic update
      final index = _requests.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _requests[index]['is_resolved'] = true;
        // Or remove it? API returns unresolved ones usually.
        // If API returns only unresolved, we should probably remove it.
        _requests.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error resolving request: $e');
    }
  }
}
