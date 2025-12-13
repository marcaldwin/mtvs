// lib/screens/clerks/clerks_home_screen.dart

import 'package:flutter/material.dart';

import '../../models/ticket_payment_models.dart';
import '../../services/payments/clerk_payment_service.dart';
import 'widgets/payment_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClerksHomeScreen extends StatefulWidget {
  const ClerksHomeScreen({super.key});

  @override
  State<ClerksHomeScreen> createState() => _ClerksHomeScreenState();
}

class _ClerksHomeScreenState extends State<ClerksHomeScreen>
    with SingleTickerProviderStateMixin {
  final _controlNoController = TextEditingController();
  final _receiptNoController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  String _searchQuery = '';

  final _service = ClerkPaymentService();
  late TabController _tabController;

  bool _loadingTicket = false;
  bool _savingPayment = false;

  bool _loadingLists = false;
  List<TicketInfo> _unpaidTickets = [];
  List<TicketInfo> _paidTickets = [];

  String? _error;
  TicketInfo? _ticket; // The currently selected ticket (detail view)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllTickets();
  }

  Future<void> _fetchAllTickets() async {
    setState(() => _loadingLists = true);
    try {
      final unpaid = await _service.getRecentUnpaidTickets();
      final paid = await _service.getRecentPaidTickets();
      if (mounted) {
        setState(() {
          _unpaidTickets = unpaid;
          _paidTickets = paid;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error loading lists: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLists = false);
      }
    }
  }

  @override
  void dispose() {
    _controlNoController.dispose();
    _receiptNoController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text(
                'Are you sure you want to logout from MTVTS?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('token');
    await prefs.remove('bearer_token');

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/auth/login', (route) => false);
  }

  Future<void> _lookupTicket([String? specificControlNo]) async {
    final controlNo = specificControlNo ?? _controlNoController.text.trim();
    if (controlNo.isEmpty) {
      setState(() {
        _error = 'Please enter a ticket control number.';
        _ticket = null;
      });
      return;
    }

    // Ensure text field is synced if we called with specificControlNo
    if (specificControlNo != null) {
      _controlNoController.text = specificControlNo;
    }

    setState(() {
      _loadingTicket = true;
      _error = null;
      _ticket = null;
    });

    try {
      final info = await _service.lookupTicket(controlNo);
      setState(() {
        _ticket = info;
        _amountController.text = info.outstandingAmount > 0
            ? info.outstandingAmount.toStringAsFixed(2)
            : '';
      });
    } on NotFoundException catch (e) {
      setState(() {
        _error = e.message;
        _ticket = null;
      });
    } on ValidationException catch (e) {
      setState(() {
        _error = e.message;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to contact server. Please try again.';
      });
    } finally {
      setState(() {
        _loadingTicket = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _ticket = null;
      _controlNoController.clear();
      _error = null;
    });
    // Refresh lists just in case
    _fetchAllTickets();
  }

  Future<void> _submitPayment() async {
    final ticket = _ticket;
    if (ticket == null) return;

    final receiptNo = _receiptNoController.text.trim();
    final amountStr = _amountController.text.trim();

    if (receiptNo.isEmpty || amountStr.isEmpty) {
      setState(() {
        _error = 'Receipt number and amount are required.';
      });
      return;
    }

    final amount = double.tryParse(amountStr.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() {
        _error = 'Invalid amount.';
      });
      return;
    }

    setState(() {
      _savingPayment = true;
      _error = null;
    });

    try {
      final updated = await _service.recordPayment(
        ticket: ticket,
        receiptNo: receiptNo,
        amount: amount,
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
      );

      setState(() {
        _ticket = updated;
        _receiptNoController.clear();
        _remarksController.clear();
        _amountController.text = updated.outstandingAmount > 0
            ? updated.outstandingAmount.toStringAsFixed(2)
            : '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully.')),
        );
      }
      
      // Refresh lists so it moves from unpaid to paid in the background
      _fetchAllTickets();
      
    } on ValidationException catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _savingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClerkHeader(onLogout: _handleLogout),
              const SizedBox(height: 16),
              
              // Search Bar always visible
              _buildSearchBar(),
              
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 12),

              Expanded(
                child: _loadingTicket
                    ? const Center(child: CircularProgressIndicator())
                    : _ticket != null
                        ? _buildDetailView()
                        : _buildTabsView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the ticket details + payment form + history
  Widget _buildDetailView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
                label: const Text(
                  'Back to List',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          TicketSummaryCard(info: _ticket!),
          const SizedBox(height: 16),
          // Only show payment form if not fully paid
          if (_ticket!.outstandingAmount > 0)
            PaymentFormCard(
              receiptController: _receiptNoController,
              amountController: _amountController,
              remarksController: _remarksController,
              isSaving: _savingPayment,
              isFullyPaid: false,
              onSubmit: _submitPayment,
            )
          else
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.green.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.green.withOpacity(0.3)),
               ),
               child: const Text(
                 'This ticket is fully paid.',
                 style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                 textAlign: TextAlign.center,
               ),
             ),

          const SizedBox(height: 16),
          const SizedBox(height: 16),
          PaymentHistorySection(
            payments: _ticket!.payments,
            onVoidPayment: _handleVoidPayment,
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoidPayment(int paymentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Payment'),
        content: const Text(
            'Are you sure you want to remove this payment? This will mark it as REVERSED.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void Payment'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loadingTicket = true);
    try {
      await _service.voidPayment(paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment reversed successfully.')),
        );
      }
      // Refresh ticket details
      _lookupTicket(_ticket!.controlNo);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
         setState(() => _error = 'Error voiding payment: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loadingTicket = false);
      }
    }
  }

  /// Shows the TabBar + TabBarView for lists
  Widget _buildTabsView() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'History'),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadingLists
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTicketList(_filterTickets(_unpaidTickets), 'No pending tickets.'),
                    _buildTicketList(_filterTickets(_paidTickets), 'No payment history found.'),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTicketList(List<TicketInfo> tickets, String emptyMsg) {
    if (tickets.isEmpty) {
      return Center(
        child: Text(
          emptyMsg,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final t = tickets[index];
        final isPaid = t.outstandingAmount <= 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.white.withOpacity(0.05),
          child: ListTile(
            title: Text(
              '${t.controlNo}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${t.violatorName} • ₱${t.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70),
            ),
            trailing: isPaid
                ? const Chip(
                    label: Text('PAID', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green,
                    visualDensity: VisualDensity.compact,
                  )
                : Text(
                    'Bal: ₱${t.outstandingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
            onTap: () => _lookupTicket(t.controlNo),
          ),
        );
      },
    );
  }

  List<TicketInfo> _filterTickets(List<TicketInfo> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((t) {
      final control = t.controlNo.toLowerCase();
      final name = t.violatorName?.toLowerCase() ?? '';
      return control.contains(_searchQuery) || name.contains(_searchQuery);
    }).toList();
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controlNoController,
            style: const TextStyle(color: Colors.white),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search name or control no...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white70,
              ),
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
            onSubmitted: (_) => _lookupTicket(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _loadingTicket ? null : () => _lookupTicket(),
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Search'),
        ),
      ],
    );
  }
}
