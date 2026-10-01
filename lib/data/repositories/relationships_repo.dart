import '../backend/backend.dart';
import '../models/relationship.dart';

class RelationshipsResult {
  const RelationshipsResult({
    this.active = const [],
    this.past = const [],
    this.maritalStatus,
  });
  final List<RelationshipState> active;
  final List<RelationshipState> past;
  final String? maritalStatus;
}

class RelationshipsRepository {
  RelationshipsRepository(this._b);
  final Backend _b;

  Future<RelationshipsResult> myRelationships() async {
    final res = Map<String, dynamic>.from(await _b.rpc('my_relationships') as Map);
    List<RelationshipState> key(String k) => (res[k] as List? ?? [])
        .whereType<Map>()
        .map((e) => RelationshipState.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return RelationshipsResult(
      active: key('active'),
      past: key('past'),
      maritalStatus: res['marital_status'] as String?,
    );
  }

  Future<RelationshipState> state(String relId) async {
    final res = await _b
        .rpc('my_relationship_state', params: {'rel_id': relId});
    return RelationshipState.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<String> proposeStage(
    String relId, {
    String? note,
    String? marriageDate,
    String? marriageType,
    String? marriageDetails,
  }) async {
    final id = await _b.rpc('propose_stage', params: {
      'rel_id': relId,
      if (note != null && note.isNotEmpty) 'note': note,
      if (marriageDate != null) 'marriage_date': marriageDate,
      if (marriageType != null) 'marriage_type': marriageType,
      if (marriageDetails != null) 'marriage_details': marriageDetails,
    });
    return id.toString();
  }

  Future<void> respondProposal(String prop, bool accept, {String? note}) =>
      _b.rpc('respond_stage_proposal', params: {
        'prop': prop,
        'accept': accept,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> withdrawProposal(String prop) =>
      _b.rpc('withdraw_stage_proposal', params: {'prop': prop});

  Future<void> pause(String relId, {String? reason}) =>
      _b.rpc('pause_relationship', params: {
        'rel_id': relId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

  Future<void> resume(String relId) =>
      _b.rpc('resume_relationship', params: {'rel_id': relId});

  // Consultation (member side)
  Future<MyConsultation> myConsultation(String relId) async {
    final res = await _b.rpc('my_consultation', params: {'rel_id': relId});
    return MyConsultation.fromJson(res as Map?);
  }

  Future<String> requestConsultation(
    String relId, {
    String? mode,
    String? availability,
    String? note,
  }) async {
    final id = await _b.rpc('request_consultation', params: {
      'rel_id': relId,
      if (mode != null) 'mode': mode,
      if (availability != null && availability.isNotEmpty)
        'availability': availability,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return id.toString();
  }

  Future<void> respondConsultation(String req, bool accept, {String? note}) =>
      _b.rpc('respond_consultation', params: {
        'req': req,
        'accept': accept,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> cancelConsultation(String req, {String? reason}) =>
      _b.rpc('cancel_consultation', params: {
        'req': req,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

  Future<void> requestReschedule(String sess, String note) =>
      _b.rpc('request_reschedule', params: {'sess': sess, 'note': note});
}
