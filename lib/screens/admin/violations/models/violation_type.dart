class ViolationType {
  final int id;
  final String code;
  final String name;
  final double fine;

  ViolationType({
    required this.id,
    required this.code,
    required this.name,
    required this.fine,
  });

  factory ViolationType.fromJson(Map<String, dynamic> j) => ViolationType(
    id: j['id'] is int ? j['id'] : int.tryParse('${j['id']}') ?? 0,
    code: '${j['code'] ?? ''}',
    name: '${j['name'] ?? ''}',
    fine: (j['fine'] is num)
        ? (j['fine'] as num).toDouble()
        : double.tryParse('${j['fine'] ?? 0}') ?? 0,
  );
}
