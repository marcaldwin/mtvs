import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../../auth/auth.dart';
import '../data/violations_repository.dart';
import '../models/violation.dart';

class AdminViolationProvider extends ChangeNotifier {
  AdminViolationProvider(this.auth) {
    _init();
  }

  final Auth auth;
  late final ViolationsRepository _repo;

  // state
  bool busy = false;
  String? error;
  int _page = 1;
  final int _perPage = 50;
  bool hasMore = true;

  String search = '';
  String? typeFilter;

  final List<Violation> items = [];

  Future<void> _init() async {
    final dio = Dio(BaseOptions(baseUrl: auth.baseUrl));
    if ((auth.token ?? '').isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer ${auth.token}';
    }
    _repo = ViolationsRepository(dio);
    await refresh();
  }

  Future<void> refresh() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      _page = 1;
      final fetched = await _repo.fetch(
        page: _page,
        perPage: _perPage,
        search: search,
        type: typeFilter,
      );
      items
        ..clear()
        ..addAll(fetched);
      hasMore = fetched.length == _perPage;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (busy || !hasMore) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final next = _page + 1;
      final fetched = await _repo.fetch(
        page: next,
        perPage: _perPage,
        search: search,
        type: typeFilter,
      );
      items.addAll(fetched);
      _page = next;
      hasMore = fetched.length == _perPage;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // filters
  void setSearch(String q) {
    search = q;
    refresh();
  }

  void setType(String? t) {
    typeFilter = t;
    refresh();
  }

  // CRUD passthroughs (optional for your create/edit screens)
  Future<void> create(Violation v) async {
    busy = true;
    notifyListeners();
    try {
      final created = await _repo.create(v);
      items.insert(0, created);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> update(Violation v) async {
    busy = true;
    notifyListeners();
    try {
      final updated = await _repo.update(v.id, v);
      final i = items.indexWhere((e) => e.id == v.id);
      if (i != -1) items[i] = updated;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> remove(int id) async {
    busy = true;
    notifyListeners();
    try {
      await _repo.remove(id);
      items.removeWhere((e) => e.id == id);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
