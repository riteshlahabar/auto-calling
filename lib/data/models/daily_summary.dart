int asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt(); // covers double
  if (v is String) return int.tryParse(v.trim()) ?? fallback;
  return fallback;
}

class DailySummary {
  final int dialedCalls;
  final int connectedCalls;
  final String serviceDay;

  DailySummary({
    required this.dialedCalls,
    required this.connectedCalls,
    required this.serviceDay,
  });

  factory DailySummary.fromMap(Map<String, dynamic> m) {
    return DailySummary(
      dialedCalls: asInt(m['dialed_calls']),
      connectedCalls: asInt(m['connected_calls']),
      serviceDay: (m['service_day'] ?? '').toString(),
    );
  }
}