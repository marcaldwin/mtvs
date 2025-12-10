import 'package:flutter/material.dart';

class ChokepointDialog extends StatefulWidget {
  const ChokepointDialog({super.key});

  @override
  State<ChokepointDialog> createState() => _ChokepointDialogState();
}

class _ChokepointDialogState extends State<ChokepointDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text('Set Chokepoint / Area'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Chokepoint / Area Name',
              hintText: 'e.g., Sudapin Crossing – Crossing A',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop(_ctrl.text.trim());
              }
            },
            child: const Text('Start Shift'),
          ),
        ],
      ),
    );
  }
}
