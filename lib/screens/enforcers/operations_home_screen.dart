// lib/screens/enforcers/operations_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/operation_provider.dart';
import '../../providers/enforcer_stats_provider.dart';
import '../../widgets/chokepoint_dialog.dart';
import 'ticket_form_screen.dart';
import '../../services/printer/printer_service.dart';
import '../../widgets/app_brand_header.dart';
import '../../widgets/logout_action.dart';
import '../../theme/app_colors.dart';

class OperationsHomeScreen extends StatefulWidget {
  const OperationsHomeScreen({super.key});

  @override
  State<OperationsHomeScreen> createState() => _OperationsHomeScreenState();
}

class _OperationsHomeScreenState extends State<OperationsHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load current shift/chokepoint + today’s stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OperationProvider>().load();
      context.read<EnforcerStatsProvider>().loadToday();
    });
  }

  Future<void> _setChokepoint() async {
    final op = context.read<OperationProvider>();
    final value = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChokepointDialog(),
    );
    if (value != null && mounted) {
      await op.startShift(value);
      // Optional: prompt to connect printer after setting chokepoint
      final printer = context.read<PrinterService>();
      await printer.ensureConnected(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OperationProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Enforcer Operations'),
        actions: const [LogoutAction()],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1222), Color(0xFF121C30)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 24),
          children: [
            const AppBrandHeader(
              title: 'Traffic Management & Enforcement',
              subtitle: 'Kidapawan City · MTVTS',
            ),
            const SizedBox(height: 16),

            // 🔹 CHOKEPOINT + ACTION CARD
            Card(
              color: AppColors.surface.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active chokepoint',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(op.chokepoint ?? '—')),
                        if (op.hasChokepoint)
                          Chip(
                            backgroundColor: AppColors.success.withOpacity(.7),
                            label: const Text('Live'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: op.hasChokepoint
                                ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TicketFormScreen(),
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.note_add),
                            label: const Text('Start New Citation'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _setChokepoint,
                            icon: const Icon(Icons.place),
                            label: Text(
                              op.hasChokepoint
                                  ? 'Change Chokepoint'
                                  : 'Set Chokepoint / Area',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 🔹 CONNECT + TEST PRINT ROW
                    Row(
                      children: [
                        // CONNECT PRINTER
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final printer = context.read<PrinterService>();

                              final ok = await printer.ensureConnected(context);
                              if (!ok) return;

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Printer connected'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.bluetooth_connected),
                            label: const Text('Connect Printer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // TEST PRINT (sample citation layout)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final printer = context.read<PrinterService>();

                              // If not connected yet, try to connect once
                              final ok =
                                  printer.isConnected ||
                                  await printer.ensureConnected(context);
                              if (!ok) return;

                              await printer.printTestTicket();

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Test citation sent to printer',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Test Print'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔹 TODAY'S SUMMARY CARD (modern style with icons)
            Consumer<EnforcerStatsProvider>(
              builder: (context, stats, _) {
                if (stats.loading) {
                  return Card(
                    color: AppColors.surface.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (stats.error != null) {
                  return Card(
                    color: AppColors.surface.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Unable to load today\'s stats.\n${stats.error}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  );
                }

                final lastTime = stats.lastCitationTime ?? '--';

                return Card(
                  color: AppColors.surface.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: AppColors.brandGradient,
                                ),
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Summary',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                ),
                                Text(
                                  'Your activity for today',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceMuted,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                label: 'Total Citations',
                                value: stats.todayCitations.toString(),
                                icon: Icons.receipt_long_rounded,
                                iconColor: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatTile(
                                label: 'Total Fines',
                                value:
                                    'PHP ${stats.todayTotalFines.toStringAsFixed(2)}',
                                icon: Icons.payments_rounded,
                                iconColor: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _StatTile(
                          label: 'Last Citation Time',
                          value: lastTime,
                          icon: Icons.schedule_rounded,
                          iconColor: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('End Shift?'),
                    content: const Text(
                      'This will clear the active chokepoint and disconnect the printer.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('End Shift'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await context.read<PrinterService>().disconnect();
                  await context.read<OperationProvider>().endShift();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('End Shift'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bg.withOpacity(0.6),
        border: Border.all(color: AppColors.onSurfaceMuted.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(.18),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
