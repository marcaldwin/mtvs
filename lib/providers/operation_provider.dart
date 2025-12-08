import 'package:flutter/foundation.dart';
import '../core/chokepoint_session.dart';

class OperationProvider extends ChangeNotifier {
  final ChokepointSession _session;

  String? _chokepoint;

  // 👇 NEW: enforcer info (for client UI & posting body if needed)
  int? _enforcerId;
  String? _enforcerName;

  OperationProvider(this._session);

  // ---------- Chokepoint ----------
  String? get chokepoint => _chokepoint;
  bool get hasChokepoint => (_chokepoint ?? '').isNotEmpty;

  // ---------- Enforcer ----------
  int? get enforcerId => _enforcerId;
  String? get enforcerName => _enforcerName;
  bool get hasEnforcer => _enforcerId != null;

  /// Load initial state from storage.
  Future<void> load() async {
    _chokepoint = await _session.getActive();
    // enforcer is not persisted yet; stays null on app start
    notifyListeners();
  }

  /// Start a shift at a chokepoint.
  Future<void> startShift(String chokepoint) async {
    await _session.setActive(chokepoint);
    _chokepoint = chokepoint;
    notifyListeners();
  }

  /// Set/update the active enforcer after successful login.
  void setEnforcer({required int id, String? name}) {
    _enforcerId = id;
    _enforcerName = name;
    notifyListeners();
  }

  /// End the shift and clear everything.
  Future<void> endShift() async {
    await _session.clear();
    _chokepoint = null;
    _enforcerId = null;
    _enforcerName = null;
    notifyListeners();
  }
}
