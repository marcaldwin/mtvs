// lib/screens/admin/payments/admin_payment_models.dart

import '../../../models/ticket_payment_models.dart';

class AdminPayment {
  final String receiptNo;
  final String controlNo;
  final String? violatorName;
  final double amount;
  final String status; // recorded | reversed
  final DateTime? paidAt;
  final String? cashierName;

  const AdminPayment({
    required this.receiptNo,
    required this.controlNo,
    this.violatorName,
    required this.amount,
    required this.status,
    this.paidAt,
    this.cashierName,
  });

  bool get isReversed => status == 'reversed';

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

    DateTime? paidAt;
    final paidAtRaw = json['paid_at'];
    if (paidAtRaw != null && paidAtRaw.toString().isNotEmpty) {
      paidAt = DateTime.tryParse(paidAtRaw.toString());
    }

    return AdminPayment(
      receiptNo: json['receipt_no'] as String? ?? '',
      controlNo: json['control_no'] as String? ?? '',
      violatorName: json['violator_name'] as String?,
      amount: amount,
      status: json['status'] as String? ?? 'recorded',
      paidAt: paidAt,
      cashierName: json['cashier_name'] as String?,
    );
      );
  }

  factory AdminPayment.fromTicketInfo(TicketInfo ticket) {
    return AdminPayment(
      receiptNo: 'PENDING',
      controlNo: ticket.controlNo,
      violatorName: ticket.violatorName,
      amount: ticket.outstandingAmount,
      status: 'unpaid',
      paidAt: null,
      cashierName: null,
    );
  }
}
}
