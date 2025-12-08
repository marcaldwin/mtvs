// lib/widgets/logout_action.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth.dart';

class LogoutAction extends StatelessWidget {
  final VoidCallback? after;
  const LogoutAction({super.key, this.after});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Log out',
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text('You will be returned to the sign-in screen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Log out'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await context.read<Auth>().logout();
          if (context.mounted) {
            after?.call();
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/auth/login', (r) => false);
          }
        }
      },
    );
  }
}
