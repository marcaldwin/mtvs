// lib/screens/admin/payments/admin_payments_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_payment_models.dart';
import 'admin_payment_service.dart';
import 'widgets/admin_payments_summary_row.dart';
import 'widgets/admin_payment_tile.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _searchController = TextEditingController();
  final _service = AdminPaymentService();

  DateTimeRange? _dateRange;
  String _statusFilter = 'all'; // all | recorded | reversed

  final _currencyFmt = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  List<AdminPayment> _payments = [];
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
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payments = await _service.fetchPayments();
      setState(() {
        _payments = payments;
      });
    } on AdminPaymentException catch (e) {
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

  List<AdminPayment> get _filteredPayments {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _payments.where((p) {
      final matchesStatus = _statusFilter == 'all' || p.status == _statusFilter;

      bool matchesDate = true;
      if (_dateRange != null && p.paidAt != null) {
        matchesDate =
            !p.paidAt!.isBefore(_dateRange!.start) &&
            !p.paidAt!.isAfter(_dateRange!.end);
      }

      final matchesSearch =
          query.isEmpty ||
          p.receiptNo.toLowerCase().contains(query) ||
          p.controlNo.toLowerCase().contains(query) ||
          (p.violatorName?.toLowerCase().contains(query) ?? false);

      return matchesStatus && matchesDate && matchesSearch;
    }).toList();

    // newest first
    filtered.sort(
      (a, b) => (b.paidAt ?? DateTime(0)).compareTo(a.paidAt ?? DateTime(0)),
    );

    return filtered;
  }

  double get _todayTotal {
    final now = DateTime.now();
    return _payments
        .where((p) {
          if (p.status != 'recorded' || p.paidAt == null) return false;
          final date = p.paidAt!.toLocal();
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  double get _monthTotal {
    final now = DateTime.now();
    return _payments
        .where((p) {
          if (p.status != 'recorded' || p.paidAt == null) return false;
          final date = p.paidAt!.toLocal();
          return date.year == now.year &&
              date.month == now.month;
        })
        .fold(0.0, (sum, p) => sum + p.amount);
  }



  @override
  Widget build(BuildContext context) {
    final txtTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPayments,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payments',
                                style: txtTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track collections, receipts, and reversals.',
                                style: txtTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Note: Refresh is now handled by RefreshIndicator, but we can keep the button or remove it.
                        // Keeping it as a manual trigger if desired, or removing to clean up.
                        // Let's keep it consistent but maybe cleaner to just use Pull-to-refresh.
                        IconButton(
                          tooltip: 'Refresh',
                          icon: const Icon(Icons.refresh_rounded),
                          color: Colors.white70,
                          onPressed: _loading ? null : _loadPayments,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Summary row
                    AdminPaymentsSummaryRow(
                      todayValue: _currencyFmt.format(_todayTotal),
                      monthValue: _currencyFmt.format(_monthTotal),
                    ),

                    const SizedBox(height: 16),

                    // Filters
                    _buildFilters(context),

                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // The List
              _buildSliverList(),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverList() {
    if (_loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    final payments = _filteredPayments;

    if (payments.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No payments match the current filters.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = payments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AdminPaymentTile(payment: p, currencyFmt: _currencyFmt),
            );
          },
          childCount: payments.length,
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final rangeLabel = _dateRange == null
        ? 'All time'
        : '${DateFormat('MMM d').format(_dateRange!.start)} - '
              '${DateFormat('MMM d, y').format(_dateRange!.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search box
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search receipt, ticket control no, or violator',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            // Date range
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: _dateRange,
                    helpText: 'Filter by payment date',
                  );

                  if (picked != null) {
                    setState(() {
                      _dateRange = picked;
                    });
                  }
                },
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(rangeLabel),
              ),
            ),
            const SizedBox(width: 8),

            // Status dropdown
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: _statusFilter,
                dropdownColor: const Color(0xFF111827),
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'recorded', child: Text('Paid')),
                  DropdownMenuItem(value: 'reversed', child: Text('Unpaid')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _statusFilter = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
