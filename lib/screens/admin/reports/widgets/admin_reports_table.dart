// lib/screens/admin/reports/widgets/admin_reports_table.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../admin_reports_models.dart';

class AdminReportsTable extends StatelessWidget {
  final List<ViolationStat> violations;
  final NumberFormat currencyFmt;

  const AdminReportsTable({
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
            'Violation Summary',
            style: txtTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Breakdown of violations within the selected date range.',
            style: txtTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (violations.isEmpty)
            const Text(
              'No violations recorded in this range.',
              style: TextStyle(color: Colors.white70),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                headingTextStyle: txtTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
                dataTextStyle: txtTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
                columns: const [
                  DataColumn(label: Text('Violation')),
                  DataColumn(label: Text('Tickets')),
                  DataColumn(label: Text('Collections')),
                ],
                rows: violations.map((v) {
                  return DataRow(
                    cells: [
                      DataCell(Text(v.violationName)),
                      DataCell(Text(v.count.toString())),
                      DataCell(Text(currencyFmt.format(v.amount))),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
