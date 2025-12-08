// lib/screens/admin/reports/admin_reports_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config.dart'; // exposes apiBaseUrl
import 'admin_reports_models.dart';

class AdminReportsService {
  AdminReportsService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  /// Fetch overview report.
  /// [from] and [to] are inclusive, in local time (date part only is used).
  Future<AdminReportOverview> fetchOverview({
    DateTime? from,
    DateTime? to,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('bearer_token');

    final params = <String, String>{};
    if (from != null) {
      params['from'] = from.toIso8601String().substring(0, 10); // YYYY-MM-DD
    }
    if (to != null) {
      params['to'] = to.toIso8601String().substring(0, 10);
    }

    final uri = Uri.parse(
      '$apiBaseUrl/admin/reports/overview',
    ).replace(queryParameters: params.isEmpty ? null : params);

    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode >= 400) {
      throw AdminReportsException(
        'Failed to load reports. (${res.statusCode})',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return AdminReportOverview.fromJson(body);
  }
}

class AdminReportsException implements Exception {
  final String message;
  AdminReportsException(this.message);

  @override
  String toString() => message;
}
