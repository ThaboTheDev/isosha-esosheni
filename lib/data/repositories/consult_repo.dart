import '../backend/backend.dart';

/// Role-gated consultant area. The server checks permissions; the app
/// only surfaces the area to permissioned members.
class ConsultRepository {
  ConsultRepository(this._b);
  final Backend _b;

  Future<Map<String, dynamic>> dashboard() async {
    final res = await _b.rpc('consultation_dashboard');
    return res is Map ? Map<String, dynamic>.from(res) : const {};
  }

  Future<Map<String, dynamic>> consultation(String req) async {
    final res = await _b.rpc('get_consultation', params: {'req': req});
    return res is Map ? Map<String, dynamic>.from(res) : const {};
  }

  Future<List<Map<String, dynamic>>> listConsultants({bool superOnly = false}) async {
    final res =
        await _b.rpc('list_consultants', params: {'super_only': superOnly});
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> assign(String req, String consultant, {String? reason}) =>
      _b.rpc('assign_consultant', params: {
        'req': req,
        'consultant': consultant,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

  Future<void> scheduleSession(
    String req, {
    required String at,
    required int minutes,
    required String mode,
    required String location,
  }) =>
      _b.rpc('schedule_session', params: {
        'req': req,
        'at': at,
        'minutes': minutes,
        'mode': mode,
        'location': location,
      });

  Future<void> updateSession(
    String sess, {
    required String st,
    String? summary,
    String? newAt,
    String? newLocation,
  }) =>
      _b.rpc('update_session', params: {
        'sess': sess,
        'st': st,
        if (summary != null) 'summary': summary,
        if (newAt != null) 'new_at': newAt,
        if (newLocation != null) 'new_location': newLocation,
      });

  Future<void> addNote(String req, String body) =>
      _b.rpc('add_consultation_note', params: {'req': req, 'body': body});

  Future<void> recordOutcome(String req, String result, String summary) =>
      _b.rpc('record_outcome', params: {
        'req': req,
        'result': result,
        'summary': summary,
      });

  Future<void> handBack(String req, String reason, {bool toSuper = false}) =>
      _b.rpc('hand_back_consultation', params: {
        'req': req,
        'reason': reason,
        'to_super': toSuper,
      });

  Future<List<Map<String, dynamic>>> householdsForReview() async {
    final res = await _b.rpc('households_for_review');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> reviewHousehold(String hh, bool approve, String note) =>
      _b.rpc('review_household', params: {
        'hh': hh,
        'approve': approve,
        'note': note,
      });
}
