import 'package:flutter/foundation.dart';
import '../data/users_repository.dart';
import '../models/admin_user.dart';

class AdminUsersProvider extends ChangeNotifier {
  AdminUsersProvider(this.repo);

  final UsersRepository repo;

  // UI state expected by your screen
  bool loading = false;
  String? error;
  String role = 'all'; // all | admin | enforcer | cashier
  String query = '';
  int _page = 1;
  final int _perPage = 20;
  bool canLoadMore = true;

  final List<AdminUser> users = [];

  Future<void> reload() => refresh();

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _page = 1;
      final items = await repo.fetchUsers(
        page: _page,
        perPage: _perPage,
        role: role,
        search: query,
      );
      users
        ..clear()
        ..addAll(items);
      canLoadMore = items.length == _perPage;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || !canLoadMore) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final next = _page + 1;
      final items = await repo.fetchUsers(
        page: next,
        perPage: _perPage,
        role: role,
        search: query,
      );
      users.addAll(items);
      _page = next;
      canLoadMore = items.length == _perPage;
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setRole(String newRole) {
    if (role == newRole) return;
    role = newRole;
    refresh();
  }

  void setSearch(String q) {
    query = q;
    refresh();
  }

  // compatibility alias used by your TextField onChanged
  void setQuery(String q) => setSearch(q);

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final updated = await repo.updateUser(id, data);
      final index = users.indexWhere((u) => u.id.toString() == id);
      if (index != -1) {
        users[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await repo.deleteUser(id);
      users.removeWhere((u) => u.id.toString() == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setPassword(String id, String newPassword) async {
    try {
      await repo.setPassword(id, newPassword);
    } catch (e) {
      rethrow;
    }
  }
}
