import 'package:dio/dio.dart';

// go from lib/screens/admin/violations -> lib/config.dart
import '../../../config.dart';

import 'models/violation.dart';

class AdminViolationPage {
  final List<Violation> items;
  final bool hasMore;

  AdminViolationPage({required this.items, required this.hasMore});
}

class AdminViolationService {
  final Dio dio;
  final String? bearerToken;

  AdminViolationService(this.dio, {this.bearerToken}) {
    // 🔧 SAFETY: ensure this Dio has a host (baseUrl)
    if (dio.options.baseUrl.isEmpty) {
      dio.options.baseUrl = apiBaseUrl; // e.g. http://192.168.1.3:8000/api
    }
  }

  Map<String, String> _authHeaders() => {
    // Force Laravel to treat this as an API request
    'Accept': 'application/json',
    if (bearerToken != null && bearerToken!.isNotEmpty)
      'Authorization': 'Bearer $bearerToken',
  };

  // LIST
  Future<AdminViolationPage> fetchViolations({
    int page = 1,
    int perPage = 50,
    String? q,
    String? type,
  }) async {
    final res = await dio.get(
      '/admin/violations',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (q != null && q.isNotEmpty) 'q': q,
        if (type != null && type.isNotEmpty) 'type': type,
      },
      options: Options(headers: _authHeaders()),
    );

    final data = res.data;

    // Backend currently returns a plain list, but support both shapes.
    late final List<dynamic> list;
    late final bool hasMore;

    if (data is List) {
      list = data;
      hasMore = false;
    } else if (data is Map<String, dynamic>) {
      list = (data['data'] as List?) ?? [];
      hasMore = data['has_more'] == true;
    } else {
      list = const [];
      hasMore = false;
    }

    final items = list
        .map((e) => Violation.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminViolationPage(items: items, hasMore: hasMore);
  }

  // CREATE
  Future<Violation> create(Violation v) async {
    final res = await dio.post(
      '/admin/violations',
      data: v.toJson(),
      options: Options(headers: _authHeaders()),
    );
    return Violation.fromJson(res.data as Map<String, dynamic>);
  }

  // UPDATE
  Future<Violation> update(Violation v) async {
    final res = await dio.put(
      '/admin/violations/${v.id}',
      data: v.toJson(),
      options: Options(headers: _authHeaders()),
    );
    return Violation.fromJson(res.data as Map<String, dynamic>);
  }

  // DELETE
  Future<void> delete(int id) async {
    await dio.delete(
      '/admin/violations/$id',
      options: Options(headers: _authHeaders()),
    );
  }
}
