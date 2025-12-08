// lib/services/payments/clerk_payment_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config.dart'; // exposes apiBaseUrl
import '../../models/ticket_payment_models.dart';

class ClerkPaymentService {
  ClerkPaymentService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Use whatever key you actually save in login
    return prefs.getString('auth_token') ??
        prefs.getString('token') ??
        prefs.getString('bearer_token');
  }

  Future<TicketInfo> lookupTicket(String controlNo) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '$apiBaseUrl/clerk/payments/ticket-lookup',
    ).replace(queryParameters: {'control_no': controlNo});

    final res = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (kDebugMode) {
      debugPrint('LOOKUP [$controlNo] => ${res.statusCode} ${res.body}');
    }

    if (res.statusCode == 404) {
      throw NotFoundException('Ticket not found.');
    }
    if (res.statusCode >= 400) {
      throw ApiException('Failed to lookup ticket. (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return TicketInfo.fromLookupApi(data);
  }

  Future<TicketInfo> recordPayment({
    required TicketInfo ticket,
    required String receiptNo,
    required double amount,
    String? remarks,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse('$apiBaseUrl/clerk/payments');

    final res = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ticket_id': ticket.ticketId,
        'amount': amount,
        'receipt_no': receiptNo,
        'remarks': remarks,
      }),
    );

    if (kDebugMode) {
      debugPrint('PAYMENT => ${res.statusCode} ${res.body}');
    }

    if (res.statusCode == 422) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      throw ValidationException(
        (data['message'] as String?) ??
            'Validation error. Please check your inputs.',
      );
    }

    if (res.statusCode >= 400) {
      throw ApiException('Failed to save payment. (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final ticketJson = data['ticket'] as Map<String, dynamic>;
    return TicketInfo.fromTicketApi(ticketJson);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}
