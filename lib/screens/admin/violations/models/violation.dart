class Violation {
  final int id;
  final String type;
  final String name;
  final double fine;
  final String? ordinanceNo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Violation({
    required this.id,
    required this.type,
    required this.name,
    required this.fine,
    this.ordinanceNo,
    this.createdAt,
    this.updatedAt,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    // id can be int or string
    final dynamic idRaw = json['id'];
    final intId = idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

    // fine can be num or string (Laravel DECIMAL)
    final dynamic fineRaw = json['fine'];
    double fineValue;
    if (fineRaw is num) {
      fineValue = fineRaw.toDouble();
    } else if (fineRaw is String) {
      fineValue = double.tryParse(fineRaw) ?? 0.0;
    } else {
      fineValue = 0.0;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return Violation(
      id: intId,
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fine: fineValue,
      ordinanceNo: json['ordinance_no'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// For create / update API calls – backend handles timestamps.
  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'fine': fine,
    'ordinance_no': ordinanceNo,
  };
}
