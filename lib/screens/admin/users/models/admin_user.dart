class AdminUser {
  final int id;

  // Core
  final String name; // canonical
  final String email;
  final String role; // admin | enforcer | cashier

  // Optional / compat fields used by your UI
  final String? fullName;
  final String? username;
  final String? enforcerNo;
  final String? employeeId;
  final String? phone;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.fullName,
    this.username,
    this.enforcerNo,
    this.employeeId,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  static DateTime? _toDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  static String _normalizeRole(Map<String, dynamic> j) {
    final r = j['role'];
    if (r is String && r.trim().isNotEmpty) return r.toLowerCase();

    if (r is Map) {
      final n = (r['slug'] ?? r['name'] ?? '').toString().toLowerCase();
      if (n.isNotEmpty) return n;
    }
    if (j['roles'] is List && (j['roles'] as List).isNotEmpty) {
      final first = Map<String, dynamic>.from(j['roles'][0] as Map);
      final n = (first['slug'] ?? first['name'] ?? '').toString().toLowerCase();
      if (n.isNotEmpty) return n;
    }
    return 'admin';
  }

  factory AdminUser.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('${v ?? ''}') ?? 0;
    }

    DateTime? _toDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    String _normalizeRole(Map<String, dynamic> m) {
      final r = m['role'];
      if (r is String && r.trim().isNotEmpty) return r.toLowerCase();
      if (r is Map) {
        final n = (r['slug'] ?? r['name'] ?? '').toString().toLowerCase();
        if (n.isNotEmpty) return n;
      }
      if (m['roles'] is List && (m['roles'] as List).isNotEmpty) {
        final first = Map<String, dynamic>.from(m['roles'][0] as Map);
        final n = (first['slug'] ?? first['name'] ?? '')
            .toString()
            .toLowerCase();
        if (n.isNotEmpty) return n;
      }
      return 'admin';
    }

    // Allow the server to return { user: {...}, ... }
    final map = Map<String, dynamic>.from(j);
    if (map['user'] is Map) {
      map.addAll(Map<String, dynamic>.from(map['user'] as Map));
    }

    final email = (map['email'] ?? '').toString();

    // Pull username from multiple possible keys
    String? username = (map['username'] ?? map['user_name'] ?? map['login'])
        ?.toString();

    // Fallback: derive from email local-part if missing/blank
    if (username == null || username.trim().isEmpty) {
      final at = email.indexOf('@');
      if (at > 0) {
        username = email.substring(0, at);
      }
    }

    final name = (map['name'] ?? map['full_name'] ?? map['fullname'] ?? '')
        .toString();

    return AdminUser(
      id: _toInt(map['id']),
      name: name,
      email: email,
      role: _normalizeRole(map),
      fullName: (map['full_name'] ?? map['fullname'] ?? map['name'])
          ?.toString(),
      username: username, // <- now always set if email exists
      enforcerNo: (map['enforcer_no'] ?? map['enforcerNo'] ?? map['badge_no'])
          ?.toString(),
      employeeId: (map['employee_id'] ?? map['employeeId'] ?? map['emp_id'])
          ?.toString(),
      phone: (map['phone'] ?? map['mobile'] ?? map['contact_no'])?.toString(),
      createdAt: _toDate(map['created_at']),
      updatedAt: _toDate(map['updated_at']),
    );
  }
}
