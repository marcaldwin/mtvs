import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool show = false;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    validator: widget.validator,
    obscureText: !show,
    onFieldSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        icon: Icon(
          show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        ),
        onPressed: () => setState(() => show = !show),
      ),
    ),
  );
}
