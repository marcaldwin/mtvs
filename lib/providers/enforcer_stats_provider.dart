import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class EnforcerStatsProvider extends ChangeNotifier {
  final Dio _dio;

  EnforcerStatsProvider(this._dio);

  bool loading = false;
  String? error;

  int todayCitations = 0;
  double todayTotalFines = 0.0;
  String? lastCitationTime; // 🔹 formatted by backend (e.g., "10:20 PM")

  Future<void> loadToday() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final res = await _dio.get('/enforcer/stats/today');
      final data = res.data as Map<String, dynamic>;

      todayCitations = (data['today_citations'] as int?) ?? 0;

      todayTotalFines = (data['today_total_fines'] as num?)?.toDouble() ?? 0.0;

      final t = data['last_citation_time'];
      lastCitationTime = (t is String && t.trim().isNotEmpty) ? t.trim() : null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
