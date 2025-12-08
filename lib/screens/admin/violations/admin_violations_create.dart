// lib/screens/admin/violations/admin_violations_create.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'admin_violation_service.dart';
import 'models/violation.dart';

class AdminViolationCreateScreen extends StatefulWidget {
  final Dio dio;
  final String? bearerToken;

  const AdminViolationCreateScreen({
    super.key,
    required this.dio,
    this.bearerToken,
  });

  @override
  State<AdminViolationCreateScreen> createState() =>
      _AdminViolationCreateScreenState();
}

class _AdminViolationCreateScreenState
    extends State<AdminViolationCreateScreen> {
  late AdminViolationService _service;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _fine = TextEditingController();
  final _type = TextEditingController();
  final _ord = TextEditingController();
  

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = AdminViolationService(
      widget.dio,
      bearerToken: widget.bearerToken,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _fine.dispose();
    _type.dispose();
    _ord.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final v = Violation(
        id: 0,
        type: _type.text.trim(),
        name: _name.text.trim(),
        fine: double.tryParse(_fine.text.trim()) ?? 0.0,
        ordinanceNo: _ord.text.trim().isEmpty ? null : _ord.text.trim(),
      );

      await _service.create(v);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Violation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _type,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            TextFormField(
              controller: _ord,
              decoration: const InputDecoration(labelText: 'Ordinance No'),
            ),
            TextFormField(
              controller: _fine,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fine (₱)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const CircularProgressIndicator()
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
