import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/violation.dart';

class AdminViolationCard extends StatelessWidget {
  final Violation violation;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const AdminViolationCard({
    super.key,
    required this.violation,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final createdLabel = violation.createdAt != null
        ? DateFormat.yMMMd().format(violation.createdAt!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(
              child: Text(
                violation.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (createdLabel.isNotEmpty)
              Text(
                createdLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
          ],
        ),
        subtitle: Text(
          '${violation.type} • ₱${violation.fine.toStringAsFixed(2)}'
          '${violation.ordinanceNo != null && violation.ordinanceNo!.isNotEmpty ? ' • ${violation.ordinanceNo}' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit ?? onTap,
        ),
      ),
    );
  }
}
