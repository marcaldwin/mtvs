import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth.dart';
import '../../widgets/password_field.dart';
import '../../widgets/app_brand_header.dart';
import '../../app/router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _S();
}

class _S extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final form = GlobalKey<FormState>();

  Future<void> _showForgotPassword(BuildContext context) async {
    final c = TextEditingController(text: email.text); // Pre-fill if they typed it
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot Password?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to request a password reset from the administrator.'),
            const SizedBox(height: 16),
            TextField(
              controller: c,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<Auth>().requestPasswordReset(c.text.trim());
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request sent! An admin will review it.')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to send request. Check internet/email.')),
                );
              }
            },
            child: const Text('Request Reset'),
          ),
        ],
      ),
    );
  }

  static const _presets = {
    'Enforcer': {'email': 'enforcer@mtvts.com', 'password': 'password123'},
    'Admin': {'email': 'admin@mtvts.com', 'password': 'password123'},
    'Cashier': {'email': 'clerk@mtvts.com', 'password': 'password123'},
  };
  String _activePreset = 'Enforcer';

  @override
  void initState() {
    super.initState();
    _applyPreset(_activePreset);
  }

  void _applyPreset(String name) {
    final p = _presets[name]!;
    email.text = p['email']!;
    pass.text = p['password']!;
    setState(() => _activePreset = name);
  }

  Future<void> _submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    final ok = await context.read<Auth>().login(email.text.trim(), pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleHomeDecider()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();

    return Scaffold(
      // default: resizeToAvoidBottomInset: true (good for keyboard)
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // so the Column can expand to full height, but still scroll
                  minHeight: constraints.maxHeight,
                ),
                child: Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppBrandHeader(
                        title: 'MTVTS',
                        subtitle: 'TMEU Kidapawan',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _presets.keys.map((label) {
                          final selected = _activePreset == label;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) => _applyPreset(label),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      PasswordField(
                        controller: pass,
                        label: 'Password',
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Minimum 6 chars'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPassword(context),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: auth.busy ? null : _submit,
                        child: auth.busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Sign in'),
                      ),
                      if (auth.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/auth/register'),
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
