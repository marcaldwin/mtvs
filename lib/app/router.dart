// lib/app/role_home_decider.dart  (replace your current file contents)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart'; // <-- needed to read Dio from context
import '../auth/auth.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/enforcers/operations_home_screen.dart';
import '../screens/clerks/clerks_home_screen.dart';
import 'roles.dart';

class RoleHomeDecider extends StatefulWidget {
  const RoleHomeDecider({super.key});

  @override
  State<RoleHomeDecider> createState() => _RoleHomeDeciderState();
}

class _RoleHomeDeciderState extends State<RoleHomeDecider> {
  bool _navigated = false;
  String _status = 'Loading roles…';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigated) return;

    final auth = context.read<Auth>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        setState(() => _status = 'Contacting server…');
        await auth.ensureRolesLoaded().timeout(const Duration(seconds: 8));

        if (!mounted || _navigated) return;

        final roles = auth.roles
            .map(RoleSlug.normalize)
            .toList(growable: false);
        debugPrint('[RoleDecider] roles => $roles');

        Widget? target;
        if (roles.contains(RoleSlug.admin)) {
          // Pass the shared Dio instance and token from the provider/auth
          target = AdminHomeScreen(
            dio: context.read<Dio>(),
            bearerToken: auth.token,
          );
        } else if (roles.contains(RoleSlug.enforcer)) {
          target = const OperationsHomeScreen();
        } else if (roles.contains(RoleSlug.cashier)) {
          target = const ClerksHomeScreen();
        }

        if (target != null) {
          _navigated = true;
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => target!));
        } else {
          setState(() => _status = 'No matching role (have: $roles).');
        }
      } on TimeoutException {
        if (!mounted) return;
        setState(
          () => _status = 'Timed out loading roles. Check network or /me.',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _status = 'Failed to load roles: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
