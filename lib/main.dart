// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import 'config.dart';

// single-file auth (HTTP + token + roles)
import 'auth/auth.dart';

// keep your existing session for other features (e.g., operations)
import 'core/chokepoint_session.dart';

// other app services/providers
import 'services/printer/printer_service.dart';
import 'providers/operation_provider.dart';
import 'screens/admin/users/providers/admin_users_provider.dart';
import 'theme/app_theme.dart';

// screens & router
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/enforcers/operations_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/clerks/clerks_home_screen.dart';
import 'app/router.dart';
import 'core/api_client.dart';
import 'screens/admin/users/data/users_repository.dart';
import 'providers/enforcer_stats_provider.dart';
import 'providers/admin_stats_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MTVTSApp());
}

class MTVTSApp extends StatelessWidget {
  const MTVTSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ----- Auth / Core -----
        ChangeNotifierProvider<Auth>(create: (_) => Auth(apiBaseUrl)),
        Provider<ChokepointSession>(create: (_) => ChokepointSession()),
        ChangeNotifierProvider<OperationProvider>(
          create: (ctx) => OperationProvider(ctx.read<ChokepointSession>()),
        ),
        ChangeNotifierProvider(create: (_) => AdminStatsProvider()),

        // ----- Printer Service (Bluetooth + ESC/POS) -----
        Provider<PrinterService>(create: (_) => PrinterService()),

        // ----- Shared Dio bound to Auth (Bearer token + baseUrl) -----
        ProxyProvider<Auth, Dio>(
          update: (_, auth, previous) {
            final dio =
                previous ??
                Dio(
                  BaseOptions(
                    baseUrl: apiBaseUrl,
                    connectTimeout: const Duration(seconds: 10),
                    receiveTimeout: const Duration(seconds: 10),
                    headers: {'Accept': 'application/json'},
                  ),
                );

            // Keep baseUrl fresh (if you ever swap envs)
            dio.options.baseUrl = apiBaseUrl;

            // Install/refresh Authorization header from Auth
            final t = auth.token ?? '';
            if (t.isNotEmpty) {
              dio.options.headers['Authorization'] = 'Bearer $t';
            } else {
              dio.options.headers.remove('Authorization');
            }

            // --- LOGGING: confirm the exact URL being called ---
            dio.interceptors.clear();
            dio.interceptors.add(
              LogInterceptor(
                request: true,
                requestHeader: true,
                requestBody: true,
                responseHeader: true,
                responseBody: false,
                error: true,
              ),
            );
            // ---------------------------------------------------

            return dio;
          },
        ),

        // ----- Enforcer stats (today's citations, fines, etc.) -----
        ChangeNotifierProvider<EnforcerStatsProvider>(
          create: (ctx) => EnforcerStatsProvider(ctx.read<Dio>()),
        ),

        // ----- Users feature wiring -----
        Provider<UsersRepository>(
          create: (ctx) => UsersRepository(ctx.read<Dio>()),
        ),
        ChangeNotifierProvider<AdminUsersProvider>(
          create: (ctx) => AdminUsersProvider(ctx.read<UsersRepository>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MTVTS',
        theme: buildAppTheme(),
        home: const _AuthGate(),
        routes: {
          '/home': (_) => const RoleHomeDecider(),
          '/auth/login': (_) => const LoginScreen(),
          '/auth/register': (_) => const RegisterScreen(),
          '/operations/home': (_) => const OperationsHomeScreen(),
          '/admin/home': (ctx) => AdminHomeScreen(
            dio: ctx.read<Dio>(),
            bearerToken: ctx.read<Auth>().token,
          ),
          '/clerks/home': (_) => const ClerksHomeScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();

    // Auth rehydrates token on startup; if not logged in, show login.
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // Ensure roles are loaded so the RoleHomeDecider can route immediately.
    auth.ensureRolesLoaded();

    return const RoleHomeDecider();
  }
}
