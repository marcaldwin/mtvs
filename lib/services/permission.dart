// lib/services/permission.dart
import 'package:permission_handler/permission_handler.dart';

class BtPermissions {
  static Future<bool> ensure() async {
    final req = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      // Some devices/Android versions still require location for BLE scan
      Permission.locationWhenInUse,
    ].request();

    final ok = req.values.every((s) => s.isGranted);
    return ok;
  }
}
