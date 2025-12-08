// lib/screens/admin/violations/admin_violation_detail.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'admin_violation_service.dart';
import 'models/violation.dart';

class AdminViolationDetailScreen extends StatefulWidget {
  final Dio dio;
  final String? bearerToken;
  final Violation initial;

  const AdminViolationDetailScreen({
    super.key,
    required this.dio,
    this.bearerToken,
    required this.initial,
  });

  @override
  State<AdminViolationDetailScreen> createState() =>
      _AdminViolationDetailScreenState();
}

class _AdminViolationDetailScreenState
    extends State<AdminViolationDetailScreen> {
  late AdminViolationService _service;
  late Violation _v;
  bool _loading = false;
  bool _saving = false;

  final _name = TextEditingController();
  final _fine = TextEditingController();
  final _type = TextEditingController();
  final _ord = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = AdminViolationService(
      widget.dio,
      bearerToken: widget.bearerToken,
    );
    _v = widget.initial;
    _name.text = _v.name;
    _fine.text = _v.fine.toStringAsFixed(2);
    _type.text = _v.type;
    _ord.text = _v.ordinanceNo ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _fine.dispose();
    _type.dispose();
    _ord.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = Violation(
        id: _v.id,
        type: _type.text.trim(),
        name: _name.text.trim(),
        fine: double.tryParse(_fine.text) ?? 0,
        ordinanceNo: _ord.text.trim(),
        createdAt: _v.createdAt,
        updatedAt: DateTime.now(),
      );
      final res = await _service.update(updated);
      setState(() => _v = res);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Violation updated')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = _v.createdAt != null
        ? DateFormat.yMMMd().format(_v.createdAt!)
        : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Violation Detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Created: $created'),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _type,
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          TextField(
            controller: _ord,
            decoration: const InputDecoration(labelText: 'Ordinance No'),
          ),
          TextField(
            controller: _fine,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Fine (₱)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
