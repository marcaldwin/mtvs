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

class _ClerksHomeScreenState extends State<ClerksHomeScreen> {
  final _controlNoController = TextEditingController();
  final _receiptNoController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  final _service = ClerkPaymentService();

  bool _loadingTicket = false;
  bool _savingPayment = false;
  String? _error;
  TicketInfo? _ticket;

  @override
  void dispose() {
    _controlNoController.dispose();
    _receiptNoController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed =
        await showDialog<bool>(
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
    // 🔑 Remove only what you actually use for auth
    await prefs.remove('auth_token');
    await prefs.remove('token');
    await prefs.remove('bearer_token');

    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/auth/login', (route) => false);
  }

  Future<void> _lookupTicket() async {
    final controlNo = _controlNoController.text.trim();
    if (controlNo.isEmpty) {
      setState(() {
        _error = 'Please enter a ticket control number.';
        _ticket = null;
      });
      return;
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
    } on ValidationException catch (e) {
      setState(() => _error = e.message);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() {
        _error = 'Unable to contact server. Please try again.';
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
      backgroundColor: bg, // keeps your dark brand background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClerkHeader(onLogout: _handleLogout),
              const SizedBox(height: 16),
              _buildSearchBar(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _loadingTicket
                    ? const Center(child: CircularProgressIndicator())
                    : _ticket == null
                    ? const Center(
                        child: Text(
                          'Search by ticket control number to start.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            TicketSummaryCard(info: _ticket!),
                            const SizedBox(height: 16),
                            PaymentFormCard(
                              receiptController: _receiptNoController,
                              amountController: _amountController,
                              remarksController: _remarksController,
                              isSaving: _savingPayment,
                              isFullyPaid: _ticket!.outstandingAmount <= 0,
                              onSubmit: _submitPayment,
                            ),
                            const SizedBox(height: 16),
                            PaymentHistorySection(payments: _ticket!.payments),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controlNoController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter ticket control number',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(
                Icons.confirmation_number,
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
          onPressed: _loadingTicket ? null : _lookupTicket,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Search'),
        ),
      ],
    );
  }
}
