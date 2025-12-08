import 'package:flutter/material.dart';
import 'package:mtvts_app/screens/admin/users/models/admin_user.dart';

class AdminUserTile extends StatelessWidget {
  final AdminUser user;
  final VoidCallback? onTap;

  const AdminUserTile({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Prefer fullName, else username, else canonical name
    final String displayName = (user.fullName?.trim().isNotEmpty ?? false)
        ? user.fullName!.trim()
        : (user.username?.trim().isNotEmpty ?? false)
        ? user.username!.trim()
        : user.name;

    return Card(
      color: const Color(0xFF0F1A2A),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFF1B2A3B),
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip('username: ${user.username ?? '—'}'),
                const SizedBox(width: 8),
                if ((user.enforcerNo?.trim().isNotEmpty ?? false))
                  _chip('enforcer: ${user.enforcerNo}'),
                if ((user.employeeId?.trim().isNotEmpty ?? false)) ...[
                  const SizedBox(width: 8),
                  _chip('employee: ${user.employeeId}'),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white70,
        ),
      ),
    );
  }
}
