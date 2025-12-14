import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'admin_bottom_nav.dart';
import 'dashboard/admin_dashbaord_screen.dart';
import 'users/admin_users_screen.dart';
import 'violations/admin_violations_screen.dart';
import 'payments/admin_payments_screen.dart';
import 'reports/admin_reports_screen.dart';
import 'dashboard/widgets/admin_brand_appbar.dart';

class AdminHomeScreen extends StatefulWidget {
  final Dio dio;
  final String? bearerToken;

  const AdminHomeScreen({super.key, required this.dio, this.bearerToken});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  /// Indices: 0=Users, 1=Violations, 2=Dashboard, 3=Payments, 4=Reports
  int _index = 2;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminBrandAppBar(),
      body: SafeArea(
        // Switch to direct widget rendering to avoid loading all tabs at once
        child: _buildBody(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _DashboardFab(
        onTap: () => _go(2),
        selected: _index == 2,
      ),
      bottomNavigationBar: AdminBottomNav(
        selectedIndex: _index,
        onChanged: _go,
      ),
    );
  }

  Widget _buildBody() {
    switch (_index) {
      case 0:
        return AdminUsersScreen();
      case 1:
        return AdminViolationsScreen(
          dio: widget.dio,
          bearerToken: widget.bearerToken,
        );
      case 2:
        return AdminDashboardScreen();
      case 3:
        return AdminPaymentsScreen();
      case 4:
        return AdminReportsScreen();
      default:
        return AdminDashboardScreen();
    }
  }
}

class _DashboardFab extends StatelessWidget {
  final VoidCallback onTap;
  final bool selected;

  const _DashboardFab({required this.onTap, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        shape: const CircleBorder(),
        elevation: selected ? 8 : 4,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.brandGradient),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
