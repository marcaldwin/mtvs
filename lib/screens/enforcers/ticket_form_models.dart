import 'package:flutter/foundation.dart';

class ViolationOption {
  final int id;
  final String type;
  final String name;
  final double fine;
  final String? ordinanceNo;

  const ViolationOption({
    required this.id,
    required this.type,
    required this.name,
    required this.fine,
    this.ordinanceNo,
  });

  factory ViolationOption.fromJson(Map<String, dynamic> json) {
    // id can be int or string
    final dynamic idRaw = json['id'];
    final intId = idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0;

    // fine can be num or string
    final dynamic fineRaw = json['fine'];
    double fineValue;
    if (fineRaw is num) {
      fineValue = fineRaw.toDouble();
    } else if (fineRaw is String) {
      fineValue = double.tryParse(fineRaw) ?? 0.0;
    } else {
      fineValue = 0.0;
    }

    if (kDebugMode) {
      // debugPrint('Parsed violation: id=$intId name=${json['name']} fine=$fineValue');
    }

    return ViolationOption(
      id: intId,
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fine: fineValue,
      ordinanceNo: json['ordinance_no'] as String?,
    );
  }
}
