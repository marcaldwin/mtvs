// lib/services/printer/printer_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../permission.dart';

class PrinterService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  bool _isConnected = false;
  String? _deviceName;

  bool get isConnected => _isConnected;
  String? get deviceName => _deviceName;

  /// Ensure we are connected to a printer.
  /// Returns true if connected, false otherwise.
  Future<bool> ensureConnected(BuildContext context) async {
    try {
      // 0) Already connected?
      if (_device != null && _writeChar != null && _isConnected) {
        return true;
      }

      // 1) Permissions
      final permsOk = await BtPermissions.ensure();
      if (!permsOk) {
        _show(context, 'Bluetooth permissions are required.');
        return false;
      }

      // 2) Check BLE support
      if (!await FlutterBluePlus.isSupported) {
        _show(context, 'Bluetooth LE not supported on this device.');
        return false;
      }

      // 3) Check adapter state
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        _show(context, 'Please turn on Bluetooth.');
        return false;
      }

      // 4) Scan properly: wait for scan to actually collect results.
      _show(context, 'Scanning for printers…');

      List<ScanResult> allResults = [];
      final sub = FlutterBluePlus.scanResults.listen((results) {
        // Latest snapshot of found devices
        allResults = results;
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 5));
      await FlutterBluePlus.stopScan();
      await sub.cancel();

      if (allResults.isEmpty) {
        _show(context, 'No Bluetooth devices found.');
        return false;
      }

      // 5) Build device list
      final devices = allResults.map((r) => r.device).toList();

      // 6) Let user pick a device (auto-pick if only one)
      BluetoothDevice? selected;

      if (devices.length == 1) {
        selected = devices.first;
      } else if (context.mounted) {
        selected = await showDialog<BluetoothDevice>(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text('Select Printer'),
            children: [
              for (final d in devices)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, d),
                  child: Text(
                    d.platformName.isNotEmpty ? d.platformName : d.remoteId.str,
                  ),
                ),
            ],
          ),
        );
      }

      if (selected == null) {
        // user cancelled dialog
        return false;
      }

      // 7) Connect
      try {
        await selected.connect(timeout: const Duration(seconds: 8));
      } catch (_) {
        // If already connected at system level, this may throw; we can ignore
      }

      _device = selected;

      // 8) Discover services and find writable characteristic
      final services = await selected.discoverServices();
      BluetoothCharacteristic? writeChar;
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            writeChar = c;
            break;
          }
        }
        if (writeChar != null) break;
      }

      if (writeChar == null) {
        _show(context, 'No writable characteristic found for printer.');
        await selected.disconnect();
        _device = null;
        return false;
      }

      _writeChar = writeChar;
      _isConnected = true;
      _deviceName = selected.platformName.isNotEmpty
          ? selected.platformName
          : selected.remoteId.str;

      _show(context, 'Printer connected: $_deviceName');
      return true;
    } catch (e) {
      _show(context, 'Printer error: $e');
      return false;
    }
  }

  /// Simple sample citation-style test print.
  Future<void> printTestTicket() async {
    if (_writeChar == null) {
      throw Exception('Printer not connected');
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    final bytes = <int>[];

    bytes.addAll(
      generator.text(
        'KIDAPAWAN CITY \nTMEU',
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          align: PosAlign.center,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        'MOBILE TRAFFIC VIOLATION',
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    // Sample citation content (NOT real data)
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Citation #', width: 6),
        PosColumn(
          text: 'SAMPLE-0001',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(generator.text('Violator : JUAN DELA CRUZ'));
    bytes.addAll(generator.text('DL No.  : N00-00-000000'));
    bytes.addAll(generator.text('Plate No.: ABC-1234'));
    bytes.addAll(generator.text('Violation: Reckless Driving'));
    bytes.addAll(generator.text('Fine     : PHP 1,500.00'));

    bytes.addAll(generator.text('Chokepoint: Sample Checkpoint'));
    bytes.addAll(generator.text('Date/Time: ${DateTime.now()}'));
    bytes.addAll(generator.hr(ch: '='));
    bytes.addAll(
      generator.text(
        'This is a SAMPLE ticket\nfor printer testing only.',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 1,
      ),
    );
    bytes.addAll(
      generator.text(
        'Pay at City Treasurer\'s Office.',
        styles: const PosStyles(bold: true, align: PosAlign.center),
        linesAfter: 2,
      ),
    );
    bytes.addAll(generator.cut());

    await _writeEscPos(Uint8List.fromList(bytes));
  }

  /// Actual citation print (when you have real ticket data).
  Future<void> printTicket({
    required String violatorName,
    required String driversLicense,
    required String plateNo,
    required String controlNo,
    required String violation,
    required String fine,
    required String chokepoint,
    required String issuedBy,
  }) async {
    if (_writeChar == null) throw Exception('Printer not connected');

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    final List<int> bytes = [];

    // 🔹 HEADER
    bytes.addAll(
      generator.text(
        'Republic of the Philippines\n'
        'Province of North Cotabato\n'
        'City of Kidapawan\n'
        'Traffic Management and\n'
        'Enforcement Unit',
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.text(
        'MOBILE TRAFFIC VIOLATION',
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr());

    // 🔹 REAL CITATION DATA
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Citation #', width: 6),
        PosColumn(
          text: controlNo,
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    bytes.addAll(generator.text('Violator : $violatorName'));
    bytes.addAll(generator.text('DL No.  : $driversLicense'));
    bytes.addAll(generator.text('Plate No.: $plateNo'));
    bytes.addAll(generator.text('Violation: $violation'));
    // ASCII only: "PHP" instead of peso sign
    bytes.addAll(generator.text('Fine     : PHP $fine'));
    bytes.addAll(generator.text('Chokepoint: $chokepoint'));
    bytes.addAll(generator.text('Date/Time: ${DateTime.now()}'));

    // 👇 NEW: show who issued the ticket
    if (issuedBy.isNotEmpty) {
      bytes.addAll(generator.text('Issued by: $issuedBy'));
    }

    bytes.addAll(generator.hr(ch: '='));

    // 🔹 FOOTER / REMINDER
    bytes.addAll(
      generator.text(
        'Please settle your citation',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(
      generator.text(
        'at the City Treasurer\'s Office.',
        styles: const PosStyles(bold: true, align: PosAlign.center),
        linesAfter: 1,
      ),
    );

    bytes.addAll(
      generator.text(
        'Keep this slip for reference.',
        styles: const PosStyles(align: PosAlign.center),
        linesAfter: 2,
      ),
    );

    bytes.addAll(generator.cut());

    await _writeEscPos(Uint8List.fromList(bytes));
  }

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _writeChar = null;
    _isConnected = false;
    _deviceName = null;
  }

  Future<void> _writeEscPos(Uint8List data) async {
    if (_writeChar == null) throw Exception('Printer characteristic missing');
    const int chunk = 180;
    for (int i = 0; i < data.length; i += chunk) {
      final part = data.sublist(
        i,
        (i + chunk > data.length) ? data.length : i + chunk,
      );
      await _writeChar!.write(
        part,
        withoutResponse: _writeChar!.properties.writeWithoutResponse,
      );
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  void _show(BuildContext ctx, String msg) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}
