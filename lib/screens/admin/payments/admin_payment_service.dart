// lib/screens/admin/payments/admin_payment_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config.dart'; // exposes apiBaseUrl
import '../../../models/ticket_payment_models.dart';
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

  Future<List<AdminPayment>> fetchUnpaidTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('bearer_token');

    // Re-using the clerk endpoint since it serves the exact purpose: getting unpaid tickets
    final uri = Uri.parse('$apiBaseUrl/clerk/payments/unpaid');

    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode >= 400) {
      // If we can't fetch unpaid (e.g. 403), just return empty to avoid breaking the whole page
      // OR throw if we want to show error. Let's log and return empty for resilience,
      // or throw to be explicit. Service usually throws.
      // throw AdminPaymentException('Failed to load unpaid tickets. (${res.statusCode})');
      // For now let's attempt to decode even if error to see message, or just throw
       throw AdminPaymentException(
        'Failed to load unpaid tickets. (${res.statusCode})',
      );
    }

    final body = jsonDecode(res.body) as List<dynamic>;
    
    return body
        .map((e) => TicketInfo.fromTicketApi(Map<String, dynamic>.from(e as Map)))
        .map((t) => AdminPayment.fromTicketInfo(t))
        .toList();
  }
}

class AdminPaymentException implements Exception {
  final String message;
  AdminPaymentException(this.message);

  @override
  String toString() => message;
}
