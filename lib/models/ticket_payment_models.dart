// lib/models/ticket_payment_models.dart

class TicketInfo {
  final int ticketId;
  final String controlNo;
  final String ticketStatus;
  final double totalAmount;
  final double totalPaid;
  final double outstandingAmount;
  final String? violatorName;
  final String? plateNo;
  final String? driversLicense;
  final List<PaymentHistory> payments;

  const TicketInfo({
    required this.ticketId,
    required this.controlNo,
    required this.ticketStatus,
    required this.totalAmount,
    required this.totalPaid,
    required this.outstandingAmount,
    required this.violatorName,
    required this.plateNo,
    required this.driversLicense,
    required this.payments,
  });

  /// For response of GET /clerk/payments/ticket-lookup
  factory TicketInfo.fromLookupApi(Map<String, dynamic> root) {
    final ticket = (root['ticket'] ?? {}) as Map<String, dynamic>;
    final violator = (root['violator'] ?? {}) as Map<String, dynamic>;
    final paymentsJson = (root['payments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final payments = paymentsJson
        .map((p) => PaymentHistory.fromJson(p))
        .toList(growable: false);

    final totalAmount = _toDouble(ticket['total_amount']);
    final paid = payments
        .where((p) => p.status == 'recorded')
        .fold<double>(0.0, (sum, p) => sum + p.amount);
    final outstanding =
        (root['outstanding_amount'] as num?)?.toDouble() ??
        (totalAmount - paid).clamp(0.0, double.infinity);

    return TicketInfo(
      ticketId: (ticket['id'] as num).toInt(),
      controlNo: ticket['control_no'] as String? ?? '',
      ticketStatus: ticket['status'] as String? ?? 'unpaid',
      totalAmount: totalAmount,
      totalPaid: paid,
      outstandingAmount: outstanding,
      violatorName: violator['name'] as String?,
      plateNo: violator['plate_no'] as String?,
      driversLicense: violator['drivers_license'] as String?,
      payments: payments,
    );
  }

  /// For response of POST /clerk/payments (we send back ticket with relations)
  factory TicketInfo.fromTicketApi(Map<String, dynamic> ticket) {
    final violator = (ticket['violator'] ?? {}) as Map<String, dynamic>;
    final paymentsJson = (ticket['payments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final payments = paymentsJson
        .map((p) => PaymentHistory.fromJson(p))
        .toList(growable: false);

    final totalAmount = _toDouble(ticket['total_amount']);
    final paid = payments
        .where((p) => p.status == 'recorded')
        .fold<double>(0.0, (sum, p) => sum + p.amount);
    final outstanding = (totalAmount - paid).clamp(0.0, double.infinity);

    return TicketInfo(
      ticketId: (ticket['id'] as num).toInt(),
      controlNo: ticket['control_no'] as String? ?? '',
      ticketStatus: ticket['status'] as String? ?? 'unpaid',
      totalAmount: totalAmount,
      totalPaid: paid,
      outstandingAmount: outstanding,
      violatorName: violator['name'] as String?,
      plateNo: violator['plate_no'] as String?,
      driversLicense: violator['drivers_license'] as String?,
      payments: payments,
    );
  }
}

class PaymentHistory {
  final double amount;
  final String receiptNo;
  final String status;
  final DateTime? paidAt;

  const PaymentHistory({
    required this.amount,
    required this.receiptNo,
    required this.status,
    required this.paidAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    final amount = _toDouble(json['amount']);
    final paidAtStr = json['paid_at']?.toString();
    final paidAt = (paidAtStr == null || paidAtStr.isEmpty)
        ? null
        : DateTime.tryParse(paidAtStr);

    return PaymentHistory(
      amount: amount,
      receiptNo: json['receipt_no'] as String? ?? '',
      status: json['status'] as String? ?? 'recorded',
      paidAt: paidAt,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
