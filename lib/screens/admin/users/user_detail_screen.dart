import 'package:flutter/material.dart';
import 'models/admin_user.dart'; // same folder as this screen

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
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Edit user tapped')));
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit User'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset password tapped')),
              );
            },
            icon: const Icon(Icons.lock_reset_rounded),
            label: const Text('Reset Password'),
          ),
        ],
      ),
    );
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
