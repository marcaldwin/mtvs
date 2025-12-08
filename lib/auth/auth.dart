// lib/auth/auth.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth extends ChangeNotifier {
  Auth(this.baseUrl) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/', // <-- normalize
      ),
    );
    debugPrint(
      '[API] baseUrl = $baseUrl',
    ); // should be http://192.168.1.8:8000/api/
    _rehydrate(); // load token from storage and set header
  }

  final String baseUrl;
  late Dio _dio;
  SharedPreferences? _prefs;

  // public state
  bool busy = false;
  String? error;
  String? token;
  Map<String, dynamic>? profile;
  List<String> roles = []; // normalized slugs: admin | enforcer | cashier

  bool get isLoggedIn => (token ?? '').isNotEmpty;

  // ---------- init / rehydrate ----------
  Future<void> _rehydrate() async {
    _prefs ??= await SharedPreferences.getInstance();
    token = _prefs?.getString(_kAuth);
    if (token != null && token!.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      // Try to fetch roles in background
      unawaited(ensureRolesLoaded());
    }
  }

  // ---------- login ----------
  Future<bool> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final res = await _dio.post(
        'auth/login',
        data: {'email': email, 'password': password},
      );

      final t = _readToken(res.data);
      if (t == null || t.isEmpty)
        throw Exception('No token in /login response');

      await _setToken(t);

      profile = _unwrapUser(res.data);
      roles = _rolesFromPayload(res.data);
      if (roles.isEmpty) {
        roles = await _meRoles();
      }

      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      busy = false;
      notifyListeners();
      return false;
    }
  }

  // ---------- register ----------
  Future<bool> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _dio.post(
        'auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role, // slug: admin | enforcer | cashier
        },
      );
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      busy = false;
      notifyListeners();
      return false;
    }
  }

  // ---------- logout ----------
  Future<void> logout() async {
    try {
      await _dio.post('auth/logout');
    } catch (_) {}
    await _clearToken();
    roles = [];
    profile = null;
    notifyListeners();
  }

  // ---------- ensure roles after app start ----------
  Future<void> ensureRolesLoaded() async {
    if (roles.isNotEmpty) return;
    if (!isLoggedIn) return;
    try {
      final r = await _meRoles();
      if (r.isNotEmpty) {
        roles = r;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ---------- helpers ----------
  static const _kAuth = 'auth_token';

  Future<void> _setToken(String t) async {
    token = t;
    _dio.options.headers['Authorization'] = 'Bearer $t';
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kAuth, t);
  }

  Future<void> _clearToken() async {
    token = null;
    _dio.options.headers.remove('Authorization');
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_kAuth);
  }

  String? _readToken(dynamic data) {
    if (data is Map) {
      if (data['token'] is String) return data['token'] as String;
      if (data['access_token'] is String) return data['access_token'] as String;
      if (data['data'] is Map && data['data']['token'] is String) {
        return data['data']['token'] as String;
      }
    }
    return null;
  }

  Map<String, dynamic>? _unwrapUser(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map) return Map<String, dynamic>.from(data['user']);
      return data;
    }
    return null;
  }

  List<String> _rolesFromPayload(dynamic data) {
    final out = <String>{};
    void add(String s) {
      final v = s.trim().toLowerCase();
      out.add(v == 'clerk' ? 'cashier' : v); // alias -> cashier
    }

    if (data is Map) {
      final r1 = data['roles'];
      if (r1 is List) {
        for (final x in r1) {
          if (x is String) add(x);
          if (x is Map && x['slug'] is String) add(x['slug']);
          if (x is Map && x['name'] is String) add(x['name']);
        }
      }
      final u = data['user'];
      if (u is Map && u['roles'] is List) {
        for (final x in (u['roles'] as List)) {
          if (x is String) add(x);
          if (x is Map && x['slug'] is String) add(x['slug']);
          if (x is Map && x['name'] is String) add(x['name']);
        }
      }
      final r2 = data['role'];
      if (r2 is String) add(r2);
      if (u is Map && u['role'] is String) add(u['role']);
    }

    const supported = {'admin', 'enforcer', 'cashier'};
    return out.where(supported.contains).toList(growable: false);
  }

  // me
  Future<List<String>> _meRoles() async {
    Response res;
    try {
      res = await _dio.get('auth/me');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        res = await _dio.get('user');
      } else {
        rethrow;
      }
    }
    return _rolesFromPayload(res.data);
  }
}
