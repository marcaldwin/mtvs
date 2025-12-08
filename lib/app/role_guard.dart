
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth.dart';
import 'roles.dart';

class RoleGuard extends StatelessWidget {
  final List<String> allow; // pass RoleSlug.* here
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allow,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final roles = context.select<Auth, List<String>>((a) => a.roles);
    return RoleSlug.any(roles, allow)
        ? child
        : (fallback ?? const _AccessDenied());
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Access denied',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
