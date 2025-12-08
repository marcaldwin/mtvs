// lib/screens/admin/reports/widgets/admin_reports_charts.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../admin_reports_models.dart';

class AdminReportsChartsSection extends StatelessWidget {
  final AdminReportOverview overview;
  final NumberFormat currencyFmt;

  const AdminReportsChartsSection({
    super.key,
    required this.overview,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CollectionsTrendCard(daily: overview.daily, currencyFmt: currencyFmt),
        const SizedBox(height: 16),
        TopViolationsCard(
          violations: overview.byViolation,
          currencyFmt: currencyFmt,
        ),
      ],
    );
  }
}

// ───────────────── Collections Trend ─────────────────

class CollectionsTrendCard extends StatelessWidget {
  final List<DailyStat> daily;
  final NumberFormat currencyFmt;

  const CollectionsTrendCard({
    super.key,
    required this.daily,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;
    final maxAmount = daily.isEmpty
        ? 0.0
        : daily.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

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
          Text(
            'Collections Trend',
            style: txtTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daily collections for the selected date range.',
            style: txtTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (daily.isEmpty)
            const Text(
              'No data available.',
              style: TextStyle(color: Colors.white70),
            )
          else
            SizedBox(
              height: 160,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use only part of the height for the bars to avoid overflow
                  final maxBarHeight = constraints.maxHeight * 0.55;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: daily.map((d) {
                      final ratio = maxAmount == 0
                          ? 0.0
                          : (d.amount / maxAmount);
                      final barHeight = maxBarHeight * ratio;

                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                d.amount == 0
                                    ? ''
                                    : currencyFmt.format(d.amount),
                                style: txtTheme.labelSmall?.copyWith(
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MM/dd').format(d.date),
                              style: txtTheme.labelSmall?.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────── Top Violations ─────────────────

class TopViolationsCard extends StatelessWidget {
  final List<ViolationStat> violations;
  final NumberFormat currencyFmt;

  const TopViolationsCard({
    super.key,
    required this.violations,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;

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
          Text(
            'Top Violations',
            style: txtTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Most frequent violations in the selected date range.',
            style: txtTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (violations.isEmpty)
            const Text(
              'No violations recorded in this range.',
              style: TextStyle(color: Colors.white70),
            )
          else
            Column(
              children: violations.map((v) {
                final subtitle = '${v.count} · ${currencyFmt.format(v.amount)}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_police_outlined,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          v.violationName,
                          style: txtTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Make the subtitle shrink instead of overflowing
                      Flexible(
                        child: Text(
                          subtitle,
                          style: txtTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.right,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
