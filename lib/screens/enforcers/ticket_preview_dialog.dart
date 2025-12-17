import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/printer/printer_service.dart';

class TicketPreviewDialog extends StatelessWidget {
  final String violatorName;
  final String driversLicense;
  final String plateNo;
  final String controlNo;
  final String violation;
  final String fine;
  final String chokepoint;
  final String issuedBy;
  final String? address;
  final String? age;
  final String? sex;
  final String? complianceDate;

  const TicketPreviewDialog({
    super.key,
    required this.violatorName,
    required this.driversLicense,
    required this.plateNo,
    required this.controlNo,
    required this.violation,
    required this.fine,
    required this.chokepoint,
    required this.issuedBy,
    this.address,
    this.age,
    this.sex,
    this.complianceDate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ticket Preview'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(),
              _buildSectionTitle('VIOLATOR INFO'),
              _buildRow('Name:', violatorName),
              _buildRow('License:', driversLicense),
              if (plateNo.isNotEmpty) _buildRow('Plate No:', plateNo),
              if (address != null && address!.isNotEmpty) _buildRow('Address:', address!),
              if ((age != null && age!.isNotEmpty) || (sex != null && sex!.isNotEmpty))
                _buildRow('Age/Sex:', '${age ?? "N/A"} / ${sex ?? "N/A"}'),
              
              const Divider(height: 24),
              _buildSectionTitle('VIOLATION DETAILS'),
              const Text('Violation:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(violation),
              const SizedBox(height: 8),
              _buildRow('Location:', chokepoint),
              _buildRow('Control No:', controlNo),

              const Divider(height: 24),
              _buildRow('TOTAL FINE:', 'P $fine', isBold: true, fontSize: 18),
              
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Issued By: $issuedBy',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Close without printing
          child: const Text('Close'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Print Now'),
          onPressed: () {
            _print(context);
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Center(
      child: Column(
        children: [
          Text('CITY OF KIDAPAWAN', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('OFFICE OF TRAFFIC MANAGEMENT', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          Text('ENFORCEMENT UNIT.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          SizedBox(height: 8),
          Text('CITATION TICKET', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, double? fontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _print(BuildContext context) async {
    final printer = context.read<PrinterService>();
    try {
      if (!printer.isConnected) {
         final connected = await printer.ensureConnected(context);
         if (!connected) return;
      }

      await printer.printTicket(
        violatorName: violatorName,
        driversLicense: driversLicense,
        plateNo: plateNo,
        controlNo: controlNo,
        violation: violation,
        fine: fine,
        chokepoint: chokepoint,
        issuedBy: issuedBy,
        address: address,
        age: age,
        sex: sex,
        complianceDate: complianceDate,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Print command sent.')),
        );
        Navigator.pop(context); // Close dialog after print
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }
}
