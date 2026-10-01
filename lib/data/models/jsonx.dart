/// Null-tolerant JSON readers. The backend omits fields the viewer may
/// not see, so every accessor must tolerate absence.
library;

String? str(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  return v is String ? v : (v == null ? null : v.toString());
}

int? intV(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? dblV(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool boolV(Map<String, dynamic>? m, String key, [bool fallback = false]) {
  final v = m?[key];
  return v is bool ? v : fallback;
}

List<String> strList(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  if (v is List) return v.whereType<String>().toList();
  return const [];
}

Map<String, dynamic>? mapV(Map<String, dynamic>? m, String key) {
  final v = m?[key];
  return v is Map<String, dynamic>
      ? v
      : (v is Map ? Map<String, dynamic>.from(v) : null);
}

List<Map<String, dynamic>> mapList(dynamic v) {
  if (v is List) {
    return v
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}
