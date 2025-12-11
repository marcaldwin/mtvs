import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class AdminBanner extends StatelessWidget {
  const AdminBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.brandGradient),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          'Manage users, violations, payments, and reports',
          style: TextStyle(color: Colors.white70),
        ),
        ),
    );
  }
}
