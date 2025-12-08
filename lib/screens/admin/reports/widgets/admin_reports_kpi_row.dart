// lib/screens/admin/reports/widgets/admin_reports_kpi_row.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../admin_reports_models.dart';

class AdminReportsKpiRow extends StatelessWidget {
  final AdminReportSummary summary;
  final NumberFormat currencyFmt;

  const AdminReportsKpiRow({
    super.key,
    required this.summary,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                label: 'Total Tickets',
                value: summary.totalTickets.toString(),
                subtitle: 'All issued tickets',
                icon: Icons.local_activity_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                label: 'Open Tickets',
                value: summary.openTickets.toString(),
                subtitle: 'Unpaid / unsettled',
                icon: Icons.warning_amber_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                label: 'Paid Tickets',
                value: summary.paidTickets.toString(),
                subtitle: 'Fully settled tickets',
                icon: Icons.verified_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _KpiCard(
                label: 'Collections',
                value: currencyFmt.format(summary.totalCollections),
                subtitle: 'Total collected in range',
                icon: Icons.payments_rounded,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: txtTheme.labelMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: txtTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: txtTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
