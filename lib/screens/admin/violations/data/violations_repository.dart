import 'package:dio/dio.dart';
import '../models/violation.dart';

class ViolationsRepository {
  ViolationsRepository(this._dio);
  final Dio _dio;

  Future<List<Violation>> fetch({
    int page = 1,
    int perPage = 50,
    String? search,
    String? type, // optional filter
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if ((search ?? '').isNotEmpty) 'q': search,
      if ((type ?? '').isNotEmpty) 'type': type,
    };

    try {
      final res = await _dio.get('/admin/violations', queryParameters: qp);
      final body = res.data;

      final list = body is Map
          ? (body['data'] ?? body['violations'] ?? body['items'] ?? [])
          : (body as List);

      return List<Violation>.from(
        list.map((e) => Violation.fromJson(Map<String, dynamic>.from(e))),
      );
    } on DioException catch (e) {
      // Treat HTTP 204 as "no rows"
      if (e.response?.statusCode == 204) return <Violation>[];
      rethrow;
    }
  }

  Future<Violation> create(Violation v) async {
    final res = await _dio.post('/admin/violations', data: v.toJson());
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    return Violation.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Violation> update(int id, Violation v) async {
    final res = await _dio.patch('/admin/violations/$id', data: v.toJson());
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    return Violation.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> remove(int id) async {
    await _dio.delete('/admin/violations/$id');
  }
}
