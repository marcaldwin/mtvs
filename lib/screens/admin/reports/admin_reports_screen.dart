// lib/screens/admin/reports/admin_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_reports_models.dart';
import 'admin_reports_service.dart';
import 'widgets/admin_reports_filters.dart';
import 'widgets/admin_reports_kpi_row.dart';
import 'widgets/admin_reports_charts.dart';
import 'widgets/admin_reports_table.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final _service = AdminReportsService();
  final _currencyFmt = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  DateTimeRange? _dateRange;
  AdminReportOverview? _overview;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final overview = await _service.fetchOverview(
        from: _dateRange?.start,
        to: _dateRange?.end,
      );
      setState(() {
        _overview = overview;
      });
    } on AdminReportsException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to contact server. Please try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _onDateRangeChanged(DateTimeRange? range) {
    setState(() => _dateRange = range);
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + export/refresh
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: txtTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generate analytics and export summaries.',
                        style: txtTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                  color: Colors.white70,
                  onPressed: _loading ? null : _loadReports,
                ),
                // Later: add export button(s)
                // IconButton(
                //   tooltip: 'Export CSV',
                //   icon: const Icon(Icons.download_rounded),
                //   color: Colors.white70,
                //   onPressed: () {},
                // ),
              ],
            ),

            const SizedBox(height: 16),

            // Filters
            AdminReportsFilters(
              dateRange: _dateRange,
              onDateRangeChanged: _onDateRangeChanged,
            ),

            const SizedBox(height: 16),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              )
            else if (_overview == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'No data available.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // KPIs
                      AdminReportsKpiRow(
                        summary: _overview!.summary,
                        currencyFmt: _currencyFmt,
                      ),
                      const SizedBox(height: 16),

                      // Trend + Top violations
                      // Trend + Top violations (stacked vertically now)
                      AdminReportsChartsSection(
                        overview: _overview!,
                        currencyFmt: _currencyFmt,
                      ),
                      const SizedBox(height: 16),

                      // Table
                      AdminReportsTable(
                        violations: _overview!.byViolation,
                        currencyFmt: _currencyFmt,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
