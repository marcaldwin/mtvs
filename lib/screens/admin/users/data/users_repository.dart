import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/admin_user.dart';

class UsersRepository {
  UsersRepository(this._dio);
  final Dio _dio;

  Future<List<AdminUser>> fetchUsers({
    int page = 1,
    int perPage = 20,
    String role = 'all', // all | admin | enforcer | cashier
    String? search,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (role.isNotEmpty && role != 'all') 'role': role,
      if ((search ?? '').isNotEmpty) 'q': search,
    };

    try {
      final res = await _dio.get('/admin/users', queryParameters: qp);

      dynamic body = res.data;
      if (body is String) {
        try {
          body = json.decode(body);
        } catch (_) {
          return <AdminUser>[];
        }
      }

      List raw;
      if (body is List) {
        raw = body;
      } else if (body is Map) {
        final m = Map<String, dynamic>.from(body);
        if (m['data'] is List) {
          raw = m['data'] as List;
        } else if (m['users'] is List) {
          raw = m['users'] as List;
        } else if (m['items'] is List) {
          raw = m['items'] as List;
        } else if (m['data'] is Map) {
          final d = Map<String, dynamic>.from(m['data'] as Map);
          raw = (d['users'] ?? d['items'] ?? d['data'] ?? []) as List;
        } else {
          raw = const [];
        }
      } else {
        raw = const [];
      }

      final out = <AdminUser>[];
      for (final e in raw) {
        if (e is Map) {
          var m = Map<String, dynamic>.from(e);
          // Flatten `{ user: {...} }` payloads so fields like username aren’t lost
          if (m['user'] is Map) {
            m.addAll(Map<String, dynamic>.from(m['user'] as Map));
          }
          out.add(AdminUser.fromJson(m));
        }
      }
      return out;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 204 || code == 404) return <AdminUser>[];
      final data = e.response?.data;
      if (data == null || (data is String && data.trim().isEmpty)) {
        return <AdminUser>[];
      }
      rethrow;
    } catch (_) {
      return <AdminUser>[];
    }
  }
}
