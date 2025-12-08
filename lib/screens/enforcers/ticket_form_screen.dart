import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/operation_provider.dart';
import '../../services/printer/printer_service.dart';
import '../../auth/auth.dart';

import 'ticket_form_models.dart';
import 'ticket_form_sections.dart';
import '../../providers/enforcer_stats_provider.dart';

class TicketFormScreen extends StatefulWidget {
  const TicketFormScreen({super.key});

  @override
  State<TicketFormScreen> createState() => _TicketFormScreenState();
}

class _TicketFormScreenState extends State<TicketFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _violatorName = TextEditingController();
  final _driversLicense = TextEditingController();
  final _plateNo = TextEditingController();

  final _fine = TextEditingController();

  bool _submitting = false;

  bool _loadingViolations = false;
  String? _violationsError;

  List<String> _violationTypes = [];
  String? _selectedType;

  List<ViolationOption> _violations = [];
  List<ViolationOption> _selectedViolations = [];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) debugPrint('TicketFormScreen.initState()');
    _loadViolationTypes();
  }

  @override
  void dispose() {
    if (kDebugMode) debugPrint('TicketFormScreen.dispose()');
    _violatorName.dispose();
    _driversLicense.dispose();
    _plateNo.dispose();
    _fine.dispose();
    super.dispose();
  }

  /// Toggle a violation in/out of the selected list and update total fine.
  void _toggleViolation(ViolationOption v, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedViolations.any((e) => e.id == v.id)) {
          _selectedViolations.add(v);
        }
      } else {
        _selectedViolations.removeWhere((e) => e.id == v.id);
      }

      final total = _selectedViolations.fold<double>(
        0.0,
        (sum, item) => sum + item.fine,
      );
      _fine.text = total > 0 ? total.toStringAsFixed(2) : '';
    });
  }

  Future<void> _loadViolationTypes() async {
    setState(() {
      _loadingViolations = true;
      _violationsError = null;
    });

    try {
      final uri = Uri.parse('$apiBaseUrl/violation-types');
      if (kDebugMode) debugPrint('GET $uri');

      final res = await http.get(uri);

      if (kDebugMode) {
        debugPrint('violation-types status: ${res.statusCode}');
        debugPrint('violation-types body: ${res.body}');
      }

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body) as List<dynamic>;
        final types = data.map((e) => e.toString()).toList();

        if (!mounted) return;
        setState(() {
          _violationTypes = types;
          if (_violationTypes.isNotEmpty) {
            _selectedType = _violationTypes.first;
            _loadViolationsForType(_selectedType!);
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          _violationsError =
              'Failed to load violation types (HTTP ${res.statusCode}).';
        });
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error loading violation types: $e');
        debugPrintStack(stackTrace: st);
      }
      if (!mounted) return;
      setState(() {
        _violationsError = 'Error loading violation types: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingViolations = false;
        });
      }
    }
  }

  Future<void> _loadViolationsForType(String type) async {
    setState(() {
      _loadingViolations = true;
      _violationsError = null;
      _violations = [];
      _selectedViolations = [];
      _fine.text = '';
    });

    try {
      final uri = Uri.parse('$apiBaseUrl/violations?type=$type');
      if (kDebugMode) debugPrint('GET $uri');

      final res = await http.get(uri);

      if (kDebugMode) {
        debugPrint('violations status: ${res.statusCode}');
        debugPrint('violations body: ${res.body}');
      }

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body) as List<dynamic>;
        final list = data
            .map((e) => ViolationOption.fromJson(e as Map<String, dynamic>))
            .toList();

        if (!mounted) return;
        setState(() {
          _violations = list;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _violationsError =
              'Failed to load violations (HTTP ${res.statusCode}).';
        });
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Error loading violations: $e');
        debugPrintStack(stackTrace: st);
      }
      if (!mounted) return;
      setState(() {
        _violationsError = 'Error loading violations: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingViolations = false;
        });
      }
    }
  }

  Future<void> _submitTicketAndPrint(BuildContext context) async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      return;
    }

    if (_selectedViolations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one violation.')),
      );
      return;
    }

    final auth = context.read<Auth>();
    final token = auth.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );
      Navigator.pushReplacementNamed(context, '/auth/login');
      return;
    }

    final op = context.read<OperationProvider>();
    final chokepoint = op.chokepoint ?? '';

    // 🔹 1) ENSURE PRINTER IS CONNECTED BEFORE SAVING
    final printer = context.read<PrinterService>();
    final printerOk = await printer.ensureConnected(context);

    if (!printerOk) {
      // Do NOT save ticket if printer is not ready
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot issue citation. Please connect a Bluetooth printer first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      // 🔹 2) BUILD REQUEST BODY
      final uri = Uri.parse('$apiBaseUrl/tickets');

      final headers = <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final bodyMap = <String, String>{
        'violator_name': _violatorName.text.trim(),
        'drivers_license': _driversLicense.text.trim(),
        'plate_no': _plateNo.text.trim(),
        'place_of_apprehension': chokepoint,
      };

      // Multi-violations: violations[0][violation_id], violations[1][violation_id], ...
      for (int i = 0; i < _selectedViolations.length; i++) {
        final v = _selectedViolations[i];
        bodyMap['violations[$i][violation_id]'] = v.id.toString();
      }

      final res = await http.post(uri, headers: headers, body: bodyMap);

      if (!mounted) return;

      if (res.statusCode != 200 && res.statusCode != 201) {
        // 🔹 API FAILED → DO NOT PRINT
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save ticket: ${res.statusCode}')),
        );
        return;
      }

      // 🔹 3) PARSE RESPONSE TO GET GENERATED CONTROL NO & ENFORCER NAME
      String controlNo = '';
      String issuedBy = '';

      try {
        final decoded = jsonDecode(res.body);

        if (decoded is Map<String, dynamic>) {
          // Case 1: { "ticket": { ... } }
          if (decoded['ticket'] is Map<String, dynamic>) {
            final ticketJson = decoded['ticket'] as Map<String, dynamic>;
            controlNo = (ticketJson['control_no'] ?? '').toString();
            issuedBy = (ticketJson['enforcer_name'] ?? '').toString();
          } else {
            // Case 2: response IS the ticket object
            controlNo = (decoded['control_no'] ?? '').toString();
            issuedBy = (decoded['enforcer_name'] ?? '').toString();
          }
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Error parsing ticket response: $e');
          debugPrintStack(stackTrace: st);
        }
      }

      if (kDebugMode) {
        debugPrint('Generated control_no from API: $controlNo');
        debugPrint('Issued by (enforcer_name): $issuedBy');
      }

      // Optional safety check
      if (controlNo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ticket saved, but no control number returned from server.',
            ),
          ),
        );
      }

      // 🔹 4) API SUCCESS → TRY TO PRINT (WITH CONTROL NO + ISSUER)
      bool printed = false;
      try {
        final violationSummary = _selectedViolations
            .map((v) => v.name)
            .join(', ');

        final fineText = _fine.text.trim().isEmpty ? '0.00' : _fine.text.trim();

        await printer.printTicket(
          violatorName: _violatorName.text.trim(),
          driversLicense: _driversLicense.text.trim(),
          plateNo: _plateNo.text.trim(),
          controlNo: controlNo, // ✅ backend-generated control number
          violation: violationSummary,
          fine: fineText,
          chokepoint: chokepoint,
          issuedBy: issuedBy, // ✅ from API (enforcer_name)
        );
        printed = true;
      } catch (e) {
        // Printer failed AFTER saving
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket saved, but printer error: $e')),
        );
      }

      // 🔹 5) FEEDBACK + REFRESH STATS + CLOSE
      if (printed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket saved. Control #: $controlNo')),
        );
      }

      // Refresh Today’s Summary on home screen
      context.read<EnforcerStatsProvider>().loadToday();

      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chokepoint = context.watch<OperationProvider>().chokepoint ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('New Citation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            ViolatorDetailsSection(
              violatorName: _violatorName,
              driversLicense: _driversLicense,
              plateNo: _plateNo,
            ),
            ViolationSection(
              violationTypes: _violationTypes,
              selectedType: _selectedType,
              violations: _violations,
              selectedViolations: _selectedViolations,
              loadingViolations: _loadingViolations,
              violationsError: _violationsError,
              fineController: _fine,
              onTypeChanged: (value) {
                setState(() => _selectedType = value);
                _loadViolationsForType(value);
              },
              onToggleViolation: _toggleViolation,
            ),
            LocationSection(chokepoint: chokepoint),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_submitting ? 'Saving...' : 'Save & Print'),
              onPressed: _submitting
                  ? null
                  : () {
                      if (kDebugMode) {
                        debugPrint('Save & Print button tapped');
                      }
                      _submitTicketAndPrint(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
