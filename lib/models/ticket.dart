class Ticket {
  final int id;
  final int violatorId;
  final int enforcerId;
  final int? violationId; // if single violation per ticket
  final double fineAmount;
  final double additionalFees;
  final double totalAmount;
  final String placeOfApprehension;
  final DateTime apprehendedAt;
  final String controlNo;
  final String status;

  Ticket({
    required this.id,
    required this.violatorId,
    required this.enforcerId,
    this.violationId,
    required this.fineAmount,
    required this.additionalFees,
    required this.totalAmount,
    required this.placeOfApprehension,
    required this.apprehendedAt,
    required this.controlNo,
    required this.status,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      violatorId: json['violator_id'],
      enforcerId: json['enforcer_id'],
      violationId: json['violation_id'],
      fineAmount: double.tryParse(json['fine_amount'].toString()) ?? 0.0,
      additionalFees:
          double.tryParse(json['additional_fees'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      placeOfApprehension: json['place_of_apprehension'] ?? '',
      apprehendedAt: DateTime.parse(json['apprehended_at']),
      controlNo: json['control_no'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'violator_id': violatorId,
      'enforcer_id': enforcerId,
      'violation_id': violationId,
      'fine_amount': fineAmount,
      'additional_fees': additionalFees,
      'total_amount': totalAmount,
      'place_of_apprehension': placeOfApprehension,
      'apprehended_at': apprehendedAt.toIso8601String(),
      'control_no': controlNo,
      'status': status,
    };
  }
}
