// lib/screens/admin/payments/admin_payment_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config.dart'; // exposes apiBaseUrl
import 'admin_payment_models.dart';

class AdminPaymentService {
  AdminPaymentService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AdminPayment>> fetchPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('bearer_token');

    final uri = Uri.parse('$apiBaseUrl/admin/payments');

    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode >= 400) {
      throw AdminPaymentException(
        'Failed to load payments. (${res.statusCode})',
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (body['data'] as List<dynamic>? ?? []);

    return list
        .map((e) => AdminPayment.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class AdminPaymentException implements Exception {
  final String message;
  AdminPaymentException(this.message);

  @override
  String toString() => message;
}
