// lib/screens/admin/payments/widgets/admin_payment_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../admin_payment_models.dart';

class AdminPaymentTile extends StatelessWidget {
  final AdminPayment payment;
  final NumberFormat currencyFmt;

  const AdminPaymentTile({
    super.key,
    required this.payment,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final isReversed = payment.isReversed;
    final statusColor = isReversed ? Colors.redAccent : Colors.greenAccent;

    final paidAtText = payment.paidAt == null
        ? 'Not set'
        : DateFormat('MMM d, y · h:mm a').format(payment.paidAt!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount + status
          Row(
            children: [
              Text(
                currencyFmt.format(payment.amount),
                style: txtTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  payment.status.toUpperCase(),
                  style: txtTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // OR / receipt
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'OR: ${payment.receiptNo}',
                  style: txtTheme.bodySmall?.copyWith(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Ticket control no
          Row(
            children: [
              const Icon(
                Icons.confirmation_number,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ticket: ${payment.controlNo}',
                  style: txtTheme.bodySmall?.copyWith(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (payment.violatorName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    payment.violatorName!,
                    style: txtTheme.bodySmall?.copyWith(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 4),

          // Paid at + cashier
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                paidAtText,
                style: txtTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              if (payment.cashierName != null)
                Text(
                  'By ${payment.cashierName}',
                  style: txtTheme.bodySmall?.copyWith(color: Colors.white54),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
