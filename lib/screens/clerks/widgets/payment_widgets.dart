// lib/screens/clerks/widgets/payment_widgets.dart

import 'package:flutter/material.dart';
import '../../../models/ticket_payment_models.dart';

class ClerkHeader extends StatelessWidget {
  final VoidCallback onLogout;

  const ClerkHeader({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onBg = Theme.of(context).colorScheme.onBackground;

    return Row(
      children: [
        // 🔹 Replace with your real logo path
        Image.asset(
          'assets/images/tmeu_logo.png',
          height: 32,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.local_police, size: 28),
        ),
        const SizedBox(width: 12),

        // title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clerk · Payments',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onBg,
                ),
              ),
              Text(
                'Search a ticket and record collections.',
                style: textTheme.bodySmall?.copyWith(
                  color: onBg.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // 🔴 Logout button (this is what was missing)
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded),
          color: onBg.withOpacity(0.85),
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class TicketSummaryCard extends StatelessWidget {
  final TicketInfo info;

  const TicketSummaryCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onBg = Theme.of(context).colorScheme.onBackground;
    final surface = Colors.white.withOpacity(0.03);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  info.controlNo,
                  style: textTheme.titleMedium?.copyWith(
                    color: onBg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusChip(status: info.ticketStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            info.violatorName ?? 'Unknown violator',
            style: textTheme.bodyMedium?.copyWith(color: onBg.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          if (info.plateNo != null || info.driversLicense != null)
            Text(
              [
                if (info.plateNo != null) 'Plate: ${info.plateNo}',
                if (info.driversLicense != null) 'DL: ${info.driversLicense}',
              ].join(' · '),
              style: textTheme.bodySmall?.copyWith(
                color: onBg.withOpacity(0.6),
              ),
            ),
          const Divider(height: 16, color: Colors.white12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AmountPill(label: 'Total', amount: info.totalAmount, color: onBg),
              AmountPill(
                label: 'Paid',
                amount: info.totalPaid,
                color: Colors.greenAccent,
              ),
              AmountPill(
                label: 'Outstanding',
                amount: info.outstandingAmount,
                color: info.outstandingAmount > 0
                    ? Colors.amberAccent
                    : Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentFormCard extends StatelessWidget {
  final TextEditingController receiptController;
  final TextEditingController amountController;
  final TextEditingController remarksController;
  final bool isSaving;
  final bool isFullyPaid;
  final VoidCallback onSubmit;

  const PaymentFormCard({
    super.key,
    required this.receiptController,
    required this.amountController,
    required this.remarksController,
    required this.isSaving,
    required this.isFullyPaid,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onBg = Theme.of(context).colorScheme.onBackground;
    final surface = Colors.white.withOpacity(0.03);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record Payment',
            style: textTheme.titleSmall?.copyWith(
              color: onBg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: receiptController,
            style: TextStyle(color: onBg),
            decoration: const InputDecoration(
              labelText: 'Official Receipt (OR) No.',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            style: TextStyle(color: onBg),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₱ ',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: remarksController,
            style: TextStyle(color: onBg),
            decoration: const InputDecoration(labelText: 'Remarks (optional)'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving || isFullyPaid ? null : onSubmit,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.payments_rounded),
              label: Text(isFullyPaid ? 'Fully Paid' : 'Record Payment'),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentHistorySection extends StatelessWidget {
  final List<PaymentHistory> payments;
  final Function(int) onVoidPayment;

  const PaymentHistorySection({
    super.key,
    required this.payments,
    required this.onVoidPayment,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final onBg = Theme.of(context).colorScheme.onBackground;
    final surface = Colors.white.withOpacity(0.02);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment History',
            style: textTheme.titleSmall?.copyWith(
              color: onBg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final p in payments) ...[
            _PaymentHistoryTile(payment: p, onVoid: () => onVoidPayment(p.id)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ── small widgets ────────────────────────────────────────────────

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPaid = status == 'paid';
    final color = isPaid ? Colors.greenAccent : colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class AmountPill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const AmountPill({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          Text(
            '₱ ${amount.toStringAsFixed(2)}',
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryTile extends StatelessWidget {
  final PaymentHistory payment;
  final VoidCallback onVoid;

  const _PaymentHistoryTile({required this.payment, required this.onVoid});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isReversed = payment.status == 'reversed';
    final color = isReversed ? Colors.redAccent : Colors.greenAccent;

    final paidAtText = payment.paidAt == null ? 'N/A' : '${payment.paidAt}';

    return Row(
      children: [
        Icon(Icons.payments_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '₱ ${payment.amount.toStringAsFixed(2)} · OR: ${payment.receiptNo} · $paidAtText',
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isReversed)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white54),
            tooltip: 'Remove',
            onPressed: onVoid,
            visualDensity: VisualDensity.compact,
          )
        else
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Text(
              'CANCELLED',
              style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
