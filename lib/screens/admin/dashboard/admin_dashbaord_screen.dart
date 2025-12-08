import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../providers/admin_stats_provider.dart';
import '../../../auth/auth.dart';
import 'widgets/admin_banner.dart';
import 'widgets/stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load stats once when screen shows
    Future.microtask(() {
      if (!mounted) return;

      final auth = context.read<Auth>();
      final token = auth.token ?? '';

      context.read<AdminStatsProvider>().load(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<AdminStatsProvider>();
    final stats = statsProvider.stats;

    final totalViolationsToday = stats?.totalCitationsToday;
    final totalEnforcers = stats?.totalEnforcers;
    final loading = statsProvider.loading;
    final error = statsProvider.error;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AdminBanner(),
        const SizedBox(height: 16),

        if (loading) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
        ] else if (error != null) ...[
          Text(error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
        ],

        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 600;
            final w = isWide ? (c.maxWidth - 12) / 2 : c.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StatCard(
                  label: 'Total Citations Today',
                  value: totalViolationsToday,
                  icon: Icons.gavel_rounded,
                  accent: Colors.redAccent,
                  width: w,
                ),
                StatCard(
                  label: 'Total Enforcers',
                  value: totalEnforcers,
                  icon: Icons.badge_rounded,
                  accent: Colors.lightBlueAccent,
                  width: w,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}








