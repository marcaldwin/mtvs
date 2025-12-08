// lib/screens/admin/reports/admin_reports_models.dart

class AdminReportOverview {
  final AdminReportSummary summary;
  final List<DailyStat> daily;
  final List<ViolationStat> byViolation;

  const AdminReportOverview({
    required this.summary,
    required this.daily,
    required this.byViolation,
  });

  /// ✅ Backward-compat with old code
  /// old name: dailyStats
  List<DailyStat> get dailyStats => daily;

  /// old name: topViolations
  List<ViolationStat> get topViolations => byViolation;

  factory AdminReportOverview.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final dailyList = (json['daily'] as List<dynamic>? ?? [])
        .map((e) => DailyStat.fromJson(e as Map<String, dynamic>))
        .toList();

    final violationList = (json['by_violation'] as List<dynamic>? ?? [])
        .map((e) => ViolationStat.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminReportOverview(
      summary: AdminReportSummary.fromJson(summaryJson),
      daily: dailyList,
      byViolation: violationList,
    );
  }
}

// ───────────────── Summary ─────────────────

class AdminReportSummary {
  final int totalTickets;
  final int openTickets;
  final int paidTickets;
  final double totalCollections;
  final double todayCollections;

  const AdminReportSummary({
    required this.totalTickets,
    required this.openTickets,
    required this.paidTickets,
    required this.totalCollections,
    required this.todayCollections,
  });

  factory AdminReportSummary.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return AdminReportSummary(
      totalTickets: _toInt(json['total_tickets']),
      openTickets: _toInt(json['open_tickets']),
      paidTickets: _toInt(json['paid_tickets']),
      totalCollections: _toDouble(json['total_collections']),
      todayCollections: _toDouble(json['today_collections']),
    );
  }
}

// ───────────────── Daily Stat ─────────────────

class DailyStat {
  final DateTime date;
  final int tickets;
  final double amount;

  const DailyStat({
    required this.date,
    required this.tickets,
    required this.amount,
  });

  factory DailyStat.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        // expecting "YYYY-MM-DD"
        return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return DailyStat(
      date: _parseDate(json['date']),
      tickets: _toInt(json['tickets']),
      amount: _toDouble(json['amount']),
    );
  }
}

// ───────────────── Violation Stat ─────────────────

class ViolationStat {
  final String violationName;
  final int count;
  final double amount;

  const ViolationStat({
    required this.violationName,
    required this.count,
    required this.amount,
  });

  /// ✅ Backward-compat with old code that uses `v.name`
  String get name => violationName;

  factory ViolationStat.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return ViolationStat(
      violationName: (json['violation_name'] ?? '') as String,
      count: _toInt(json['count']),
      amount: _toDouble(json['amount']),
    );
  }
}
