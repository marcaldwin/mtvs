import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/admin_user.dart';
import 'providers/admin_users_provider.dart';

class UserDetailScreen extends StatelessWidget {
  final AdminUser user;
  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final accent = Colors.blueAccent;

    final displayName =
        (user.fullName != null && user.fullName!.trim().isNotEmpty)
        ? user.fullName!
        : user.name;

    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accent.withOpacity(.15),
                child: Icon(Icons.person, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill('username: ${user.username}', accent),
                        if ((user.enforcerNo ?? '').isNotEmpty)
                          _pill(
                            'enforcer no: ${user.enforcerNo}',
                            Colors.lightBlueAccent,
                          ),
                        if ((user.employeeId ?? '').isNotEmpty)
                          _pill(
                            'employee id: ${user.employeeId}',
                            Colors.tealAccent,
                          ),
                         _pill('role: ${user.role}', Colors.orangeAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          _kv('Full name', user.fullName),
          _kv('Username', user.username),
          _kv('Email', user.email),
          if ((user.enforcerNo ?? '').isNotEmpty)
            _kv('Enforcer No.', user.enforcerNo!),
          if ((user.employeeId ?? '').isNotEmpty)
            _kv('Employee ID', user.employeeId!),
          if (user.createdAt != null)
            _kv('Created', user.createdAt!.toLocal().toString()),
          if (user.updatedAt != null)
            _kv('Updated', user.updatedAt!.toLocal().toString()),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit User'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _showSetPasswordDialog(context),
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('Reset Password'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete),
            label: const Text('Delete User'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final nameCtrl = TextEditingController(text: user.fullName ?? user.name);
    final emailCtrl = TextEditingController(text: user.email);
    String roleStart = user.role.toLowerCase();
    // basic sanitization to match dropdown items
    if (!['admin', 'enforcer', 'cashier'].contains(roleStart)) {
      roleStart = 'admin'; 
    }
    String role = roleStart;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'enforcer', child: Text('Enforcer')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                ],
                onChanged: (v) {
                  if (v != null) role = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateUser(
                context, 
                nameCtrl.text.trim(), 
                emailCtrl.text.trim(), 
                role,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser(
    BuildContext context, 
    String name, 
    String email, 
    String role,
  ) async {
    final provider = context.read<AdminUsersProvider>();
    try {
      await provider.updateUser(user.id.toString(), {
        'full_name': name,
        'email': email,
        'role': role,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.pop(context); // Go back to list to see changes
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteUser(context);
    }
  }

  Future<void> _deleteUser(BuildContext context) async {
    final provider = context.read<AdminUsersProvider>();
    try {
      await provider.deleteUser(user.id.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        Navigator.pop(context); // Return to list
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deletion failed: $e')),
        );
      }
    }
  }
  
  Future<void> _showSetPasswordDialog(BuildContext context) async {
    final passCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set New Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter a new password for "${user.name}". This will overwrite their current password.'),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
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
              if (passCtrl.text.length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              Navigator.pop(ctx);
              _setPassword(context, passCtrl.text);
            },
            child: const Text('Set Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _setPassword(BuildContext context, String newPassword) async {
    final provider = context.read<AdminUsersProvider>();
    try {
      await provider.setPassword(user.id.toString(), newPassword);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set password: $e')),
        );
      }
    }
  }

  static Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _kv(String key, String? value) {
    final v = (value == null || value.trim().isEmpty) ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
