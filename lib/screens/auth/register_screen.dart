import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth.dart';
import '../../widgets/password_field.dart';
import '../../widgets/app_brand_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _S();
}

enum UserRole { enforcer, admin, cashier }

String roleToApi(UserRole r) => r.name; // matches DB slugs

class _S extends State<RegisterScreen> {
  final name = TextEditingController(),
      email = TextEditingController(),
      pass = TextEditingController(),
      confirm = TextEditingController();
  final form = GlobalKey<FormState>();

  UserRole role = UserRole.enforcer;

  Future<void> _submit() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if (confirm.text != pass.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final ok = await context.read<Auth>().register(
      name.text.trim(),
      email.text.trim(),
      pass.text,
      roleToApi(role),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registered')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: form,
            child: ListView(
              children: [
                const AppBrandHeader(
                  title: 'MTVTS',
                  subtitle: 'TMEU Kidapawan',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.enforcer,
                      child: Text('Enforcer'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.cashier,
                      child: Text('Cashier'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => role = v ?? UserRole.enforcer),
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: pass,
                  label: 'Password',
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimum 6 chars' : null,
                ),
                const SizedBox(height: 12),
                PasswordField(controller: confirm, label: 'Confirm password'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: auth.busy ? null : _submit,
                  child: auth.busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
