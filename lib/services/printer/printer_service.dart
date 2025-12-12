// lib/services/printer/printer_service.dart
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:image/image.dart' as img;

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
      // 0) Check if we are physically connected
      if (_device != null && _writeChar != null) {
        // Check actual BLE state
        final state = await _device!.connectionState.first;
        if (state == BluetoothConnectionState.connected) {
           return true;
        } else {
           // Not connected? Reset local state and try full reconnect
           _isConnected = false;
        }
      }
      
      // If we fall through here, we need to scan/connect

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

      // 🔹 AUTO-RECONNECT OPTIMIZATION:
      // If we lost connection to a device we just had, try to find it in the list and reconnect auto-magically
      if (_device != null) {
        try {
          final sameDevice = devices.firstWhere((d) => d.remoteId == _device!.remoteId);
          selected = sameDevice;
        } catch (_) {}
      }

      if (selected == null) {
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
      }

      if (selected == null) {
        // user cancelled dialog
        return false;
      }

      // 7) Connect
      try {
        // Attempt connect
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
      String msg = 'Printer error: $e';

      // 🔹 User-friendly error mapping
      final str = e.toString();
      if (str.contains('Location services are required') || str.contains('Location services are disabled')) {
        msg = 'Please enable Location/GPS to scan for printers.';
      } else if (str.contains('Bluetooth is turned off') || str.contains('BluetoothAdapterState')) {
         msg = 'Please turn on Bluetooth.';
      }

      _show(context, msg);
      return false;
    }
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
    String? address,
    String? age,
    String? sex,
    String? complianceDate,
  }) async {
    if (_writeChar == null) throw Exception('Printer not connected');

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final List<int> bytes = [];

    // ---------------------------------------------------------
    // HEADER
    // ---------------------------------------------------------
    bytes.addAll(generator.text(
      'MUNICIPALITY OF KIDAPAWAN',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    ));
    bytes.addAll(generator.text(
      'OFFICE OF THE MAYOR',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    ));
    bytes.addAll(generator.text(
      'CITATION TICKET',
      styles: const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.hr());

    // ---------------------------------------------------------
    // VIOLATOR INFO
    // ---------------------------------------------------------
    bytes.addAll(generator.text('NAME: $violatorName'));
    bytes.addAll(generator.text('LICENSE: $driversLicense'));

    if (plateNo.isNotEmpty) {
      bytes.addAll(generator.text('PLATE NO: $plateNo'));
    }

    if (address != null && address.isNotEmpty) {
      bytes.addAll(generator.text('ADDRESS: $address'));
    }

    final ageText = age ?? 'N/A';
    final sexText = sex ?? 'N/A';
    bytes.addAll(generator.text('AGE/SEX: $ageText / $sexText'));

    bytes.addAll(generator.hr());

    // ---------------------------------------------------------
    // VIOLATION DETAILS
    // ---------------------------------------------------------
    bytes.addAll(generator.text('VIOLATION:'));
    bytes.addAll(generator.text(violation, styles: const PosStyles(align: PosAlign.left)));
    bytes.addAll(generator.feed(1));

    bytes.addAll(generator.text('LOCATION: $chokepoint'));
    bytes.addAll(generator.text('CONTROL NO: $controlNo'));

    bytes.addAll(generator.hr());

    // ---------------------------------------------------------
    // FINE
    // ---------------------------------------------------------
    bytes.addAll(generator.text(
      'TOTAL FINE: P $fine',
      styles: const PosStyles(bold: true),
    ));

    // ---------------------------------------------------------
    // SIGNATURES
    // ---------------------------------------------------------
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'ISSUED BY: $issuedBy',
      styles: const PosStyles(bold: true, align: PosAlign.center),
    ));
    
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text(
      '____________________________',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.text(
      'Signature of Violator',
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(generator.feed(3));
    bytes.addAll(generator.cut());

    await _writeEscPos(Uint8List.fromList(bytes));
  }

  /// Simple sample print to test connection
  Future<void> printTestTicket() async {
    // Just re-use printTicket with sample data
    await printTicket(
      violatorName: 'JUAN DELA CRUZ',
      driversLicense: 'N00-00-0000',
      plateNo: 'ABC-123',
      controlNo: '000101',
      violation: 'FOR NOT WEARING FACE MASK\n(First Offense)',
      fine: '150.00',
      chokepoint: 'MAIN HIGHWAY',
      issuedBy: 'OFFICER DADO',
      age: '30',
      sex: 'M',
      address: 'POBLACION, NABUNTURAN',
    );
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

  // Adjusted _writeEscPos for maximum reliability on cheap printers
  Future<void> _writeEscPos(Uint8List data) async {
    if (_writeChar == null) throw Exception('Printer characteristic missing');
    
    // Reduce chunk size significantly to prevent buffer overflow
    const int chunk = 20; 
    
    for (int i = 0; i < data.length; i += chunk) {
      final part = data.sublist(
        i,
        (i + chunk > data.length) ? data.length : i + chunk,
      );
      
      await _writeChar!.write(
        part,
        withoutResponse: _writeChar!.properties.writeWithoutResponse,
      );
      
      // Increase delay significantly to allow printer to process
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _show(BuildContext ctx, String msg) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}
