import 'package:flutter/material.dart';
import '../models/admin_user.dart';

class UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback? onTap;

  const UserCard({super.key, required this.user, this.onTap});

  // Simple accent derived from username/email so every card gets a stable color
  Color _accent(BuildContext context) {
    final seedSource = '${user.username ?? user.name}${user.email}';
    final seed = seedSource.hashCode;
    final hues = <Color>[
      Colors.tealAccent,
      Colors.lightBlueAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];
    return hues[seed.abs() % hues.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    // Prefer fullName, else username, else canonical name
    final String displayName = (user.fullName?.trim().isNotEmpty ?? false)
        ? user.fullName!.trim()
        : (user.username?.trim().isNotEmpty ?? false)
        ? user.username!.trim()
        : user.name;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF192231),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(.06)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: accent.withOpacity(.15),
              child: Icon(Icons.person, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName, // non-null
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: [
                      _Pill(
                        label: 'username: ${user.username ?? '—'}',
                        color: accent,
                      ),
                      if ((user.enforcerNo?.trim().isNotEmpty ?? false))
                        _Pill(
                          label: 'enforcer: ${user.enforcerNo}',
                          color: Colors.lightBlueAccent,
                        ),
                      if ((user.employeeId?.trim().isNotEmpty ?? false))
                        _Pill(
                          label: 'employee: ${user.employeeId}',
                          color: Colors.tealAccent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
