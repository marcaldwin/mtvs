// lib/screens/admin/reports/widgets/admin_reports_filters.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminReportsFilters extends StatelessWidget {
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  const AdminReportsFilters({
    super.key,
    required this.dateRange,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rangeLabel = dateRange == null
        ? 'All time'
        : '${DateFormat('MMM d').format(dateRange!.start)} - '
              '${DateFormat('MMM d, y').format(dateRange!.end)}';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 1),
                initialDateRange: dateRange,
                helpText: 'Filter by ticket date',
              );

              onDateRangeChanged(picked);
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(rangeLabel),
          ),
        ),
        const SizedBox(width: 8),
        // Quick actions if you want later (Today, This Month, etc.)
      ],
    );
  }
}
