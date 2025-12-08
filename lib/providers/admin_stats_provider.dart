// lib/providers/admin_stats_provider.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class AdminStats {
  final int totalCitationsToday;
  final int totalEnforcers;

  const AdminStats({
    required this.totalCitationsToday,
    required this.totalEnforcers,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalCitationsToday:
          (json['total_citations_today'] as num?)?.toInt() ?? 0,
      totalEnforcers: (json['total_enforcers'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminStatsProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  AdminStats? _stats;

  bool get loading => _loading;
  String? get error => _error;
  AdminStats? get stats => _stats;

  /// Load stats using a bearer token (no BuildContext here).
  Future<void> load(String token) async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (token.isEmpty) {
        _error = 'Not authenticated';
        _loading = false;
        notifyListeners();
        return;
      }

      final uri = Uri.parse('$apiBaseUrl/admin/stats');
      if (kDebugMode) debugPrint('GET $uri');

      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        debugPrint('admin/stats status: ${res.statusCode}');
        debugPrint('admin/stats body: ${res.body}');
      }

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _stats = AdminStats.fromJson(data);
      } else {
        _error = 'Failed to load stats (HTTP ${res.statusCode})';
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error loading admin stats: $e');
        debugPrintStack(stackTrace: st);
      }
      _error = 'Error loading stats: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
