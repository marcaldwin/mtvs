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

    // 🔹 1. LOGO
    try {
      final ByteData data = await rootBundle.load('assets/images/tmeu_logo.png');
      final Uint8List imgBytes = data.buffer.asUint8List();
      final img.Image? originalImage = img.decodeImage(imgBytes);

      if (originalImage != null) {
        final img.Image resized = img.copyResize(originalImage, width: 140);
        await _writeEscPos(Uint8List.fromList(generator.image(resized)));
        await Future.delayed(const Duration(milliseconds: 1000)); // Big pause after image
      }
    } catch (e) {
      debugPrint('Error printing logo: $e');
    }

    // 🔹 2. HEADER PART 1 (Republic...)
    final List<int> header1 = [];
    header1.addAll(generator.text(
      'Republic of the Philippines\n'
      'Province of North Cotabato\n'
      'MUNICIPALITY OF KIDAPAWAN\n'
      'OFFICE OF THE MAYOR',
      styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size1),
    ));
    header1.addAll(generator.feed(1));
    await _writeEscPos(Uint8List.fromList(header1));
    await Future.delayed(const Duration(milliseconds: 500)); 

    // 🔹 2. HEADER PART 2 (CITATION TICKET)
    final List<int> header2 = [];
    header2.addAll(generator.text('CITATION TICKET', styles: const PosStyles(bold: true, align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2)));
    await _writeEscPos(Uint8List.fromList(header2));
    await Future.delayed(const Duration(milliseconds: 500)); 

    // 🔹 2. HEADER PART 3 (Ordinance)
    final List<int> header3 = [];
    header3.addAll(generator.text('NEW NORMAL ORDINANCE NO. 06', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));
    header3.addAll(generator.hr());
    await _writeEscPos(Uint8List.fromList(header3));
    await Future.delayed(const Duration(milliseconds: 500)); 
    
    // 🔹 3. DETAILS (Name, Age, Address, Etc)
    final List<int> details = [];
    details.addAll(generator.row([
      PosColumn(text: 'NAME: $violatorName', width: 9, styles: const PosStyles(fontType: PosFontType.fontB)),
      PosColumn(text: 'AGE: ${age ?? ''}', width: 3, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
    ]));

    details.addAll(generator.row([
      PosColumn(text: 'ADDRESS: ${address ?? ''}', width: 8, styles: const PosStyles(fontType: PosFontType.fontB)),
      PosColumn(text: 'SEX: ${sex ?? ''}', width: 4, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
    ]));

    details.addAll(generator.text('DATE/TIME: ${DateTime.now().toString().substring(0, 16)}', styles: const PosStyles(fontType: PosFontType.fontB)));
    
    if (complianceDate != null && complianceDate.isNotEmpty) {
      details.addAll(generator.text('COMPLIANCE DATE: $complianceDate', styles: const PosStyles(fontType: PosFontType.fontB)));
    }
    
    details.addAll(generator.hr());
    
    await _writeEscPos(Uint8List.fromList(details));
    await Future.delayed(const Duration(milliseconds: 500));

    // 🔹 4. VIOLATION LIST
    final List<int> violations = [];
    violations.addAll(generator.text('VIOLATIONS:', styles: const PosStyles(bold: true, underline: true)));
    violations.addAll(generator.row([ PosColumn(text: '[ ] A. FOR NOT WEARING FACE MASK', width: 12) ]));
    violations.addAll(generator.row([ PosColumn(text: '[ ] B. NOT PRACTICING DISTANCING', width: 12) ]));
    violations.addAll(generator.row([ PosColumn(text: '[ ] C. VIOLATION OF CURFEW', width: 12) ]));
    violations.addAll(generator.row([ PosColumn(text: '[ ] D. OTHER ACTS', width: 12) ]));
    violations.addAll(generator.row([ PosColumn(text: '[ ] E. BUSINESS ESTABLISHMENTS', width: 12) ]));

    violations.addAll(generator.feed(1));
    violations.addAll(generator.text('ACTUAL VIOLATION:', styles: const PosStyles(bold: true)));
    violations.addAll(generator.text('> $violation')); // The one selected
    violations.addAll(generator.text('control #: $controlNo', styles: const PosStyles(bold: true)));
    
    await _writeEscPos(Uint8List.fromList(violations));
    await Future.delayed(const Duration(milliseconds: 500));

    // 🔹 5. FOOTER
    final List<int> footer = [];
    footer.addAll(generator.feed(1));
    footer.addAll(generator.row([
      PosColumn(text: 'TOTAL PENALTY:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'P $fine', width: 6, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]));

    footer.addAll(generator.hr(ch: '_'));
    footer.addAll(generator.feed(2));
    
    footer.addAll(generator.text(issuedBy.toUpperCase(), styles: const PosStyles(align: PosAlign.center, underline: true)));
    footer.addAll(generator.text('Apprehending Officer', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));
    footer.addAll(generator.feed(2));
    footer.addAll(generator.text('____________________________', styles: const PosStyles(align: PosAlign.center)));
    footer.addAll(generator.text('Signature of Violator', styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));

    footer.addAll(generator.feed(3));
    footer.addAll(generator.cut());

    await _writeEscPos(Uint8List.fromList(footer));
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
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _show(BuildContext ctx, String msg) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }
}
