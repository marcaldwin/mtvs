import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ticket_form_models.dart';

/// ------------------------------------------------------------
/// VIOLATOR DETAILS
/// ------------------------------------------------------------
class ViolatorDetailsSection extends StatelessWidget {
  final TextEditingController violatorName;
  final TextEditingController driversLicense;
  final TextEditingController plateNo;
  final TextEditingController sex;
  final TextEditingController age;
  final TextEditingController address;
  final TextEditingController complianceDate;

  const ViolatorDetailsSection({
    super.key,
    required this.violatorName,
    required this.driversLicense,
    required this.plateNo,
    required this.sex,
    required this.age,
    required this.address,
    required this.complianceDate,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Violator Details',
      children: [
        TextFormField(
          controller: violatorName,
          decoration: const InputDecoration(labelText: 'Violator Name'),
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: age,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: sex.text.isNotEmpty ? sex.text : null,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Male')),
                  DropdownMenuItem(value: 'F', child: Text('Female')),
                ],
                onChanged: (val) {
                  if (val != null) sex.text = val;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: address,
          decoration: const InputDecoration(labelText: 'Address'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: driversLicense,
          decoration: const InputDecoration(labelText: 'Driver\'s License No.'),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
          ],
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: plateNo,
          decoration: const InputDecoration(labelText: 'Plate No. (optional)'),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\-]')),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 4),
        TextFormField(
          controller: complianceDate,
          decoration: const InputDecoration(
            labelText: 'Compliance Date',
            suffixIcon: Icon(Icons.calendar_today),
            helperText: 'YYYY-MM-DD'
          ),
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode()); // hide keyboard
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now.add(const Duration(days: 7)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (picked != null) {
              // Format: YYYY-MM-DD
              complianceDate.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
            }
          },
        ),
      ],
    );
  }
}


/// ------------------------------------------------------------
/// VIOLATIONS (multi-select)
/// ------------------------------------------------------------
class ViolationSection extends StatelessWidget {
  final List<String> violationTypes;
  final String? selectedType;

  final List<ViolationOption> violations;
  final List<ViolationOption> selectedViolations;

  final bool loadingViolations;
  final String? violationsError;

  final TextEditingController fineController;

  final ValueChanged<String> onTypeChanged;
  final void Function(ViolationOption, bool) onToggleViolation;

  const ViolationSection({
    super.key,
    required this.violationTypes,
    required this.selectedType,
    required this.violations,
    required this.selectedViolations,
    required this.loadingViolations,
    required this.violationsError,
    required this.fineController,
    required this.onTypeChanged,
    required this.onToggleViolation,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Violations',
      children: [
        // 🔹 Type filter
        DropdownButtonFormField<String>(
          value: selectedType,
          decoration: const InputDecoration(labelText: 'Violation Type'),
          items: violationTypes
              .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onTypeChanged(value);
          },
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),

        if (loadingViolations) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
        ] else ...[
          // 🔹 List of checkboxes for each violation
          if (violations.isNotEmpty)
            Column(
              children: violations.map((v) {
                final checked = selectedViolations.any((e) => e.id == v.id);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (val) => onToggleViolation(v, val ?? false),
                  dense: true,
                  title: Text(v.name),
                  subtitle: Text(
                    'Fine: ₱ ${v.fine.toStringAsFixed(2)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                );
              }).toList(),
            )
          else
            const Text(
              'No violations found for this type.',
              style: TextStyle(fontSize: 12),
            ),
        ],

        const SizedBox(height: 12),

        // 🔹 Total fine field (read-only)
        TextFormField(
          controller: fineController,
          readOnly: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Total Fine (₱)',
            helperText: 'Sum of all selected violations',
          ),
          validator: (_) => selectedViolations.isEmpty
              ? 'Select at least one violation'
              : null,
        ),

        if (violationsError != null) ...[
          const SizedBox(height: 8),
          Text(
            violationsError!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// ------------------------------------------------------------
/// LOCATION
/// ------------------------------------------------------------
class LocationSection extends StatelessWidget {
  final String chokepoint;

  const LocationSection({super.key, required this.chokepoint});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Location',
      children: [
        TextFormField(
          enabled: false,
          initialValue: chokepoint,
          decoration: const InputDecoration(
            labelText: 'Place of Apprehension (chokepoint)',
            helperText: 'Auto-filled from active shift',
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// SHARED CARD WIDGET
/// ------------------------------------------------------------
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
