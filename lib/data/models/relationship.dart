import 'jsonx.dart';

const List<String> stageOrder = [
  'talking',
  'consultation',
  'dating',
  'courtship',
  'marriage_preparation',
  'married',
];

const Map<String, String> stageLabels = {
  'talking': 'Talking',
  'consultation': 'Consultation',
  'dating': 'Dating',
  'courtship': 'Courtship',
  'marriage_preparation': 'Preparation',
  'married': 'Married',
};

const Map<String, String> marriageTypes = {
  'customary': 'Customary',
  'civil': 'Civil',
  'customary_and_civil': 'Customary and civil',
  'religious': 'Religious',
  'other': 'Other',
};

class GateState {
  const GateState({
    this.ok = false,
    this.target,
    this.targetLabel,
    this.reasons = const [],
    this.proposalWaiting = false,
    this.paused = false,
  });

  final bool ok;
  final String? target;
  final String? targetLabel;
  final List<String> reasons;
  final bool proposalWaiting;
  final bool paused;

  static GateState fromJson(Map<String, dynamic>? m) => GateState(
        ok: boolV(m, 'ok'),
        target: str(m, 'target'),
        targetLabel: str(m, 'target_label'),
        reasons: strList(m, 'reasons'),
        proposalWaiting: boolV(m, 'proposal_waiting'),
        paused: boolV(m, 'paused'),
      );
}

class TimelineEntry {
  const TimelineEntry({required this.stage, required this.at, this.endedAt});
  final String stage;
  final String at;
  final String? endedAt;

  static TimelineEntry fromJson(Map<String, dynamic> m) => TimelineEntry(
        stage: str(m, 'stage') ?? '',
        at: str(m, 'at') ?? '',
        endedAt: str(m, 'ended_at'),
      );
}

class StageProposal {
  const StageProposal({
    required this.id,
    required this.targetStage,
    this.note,
    this.fromId,
    this.marriageDate,
    this.marriageType,
    this.marriageDetails,
  });

  final String id;
  final String targetStage;
  final String? note;
  final String? fromId;
  final String? marriageDate;
  final String? marriageType;
  final String? marriageDetails;

  static StageProposal? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return StageProposal(
      id: str(m, 'id') ?? '',
      targetStage: str(m, 'target_stage') ?? '',
      note: str(m, 'note'),
      fromId: str(m, 'from_id') ?? str(m, 'proposed_by'),
      marriageDate: str(m, 'marriage_date'),
      marriageType: str(m, 'marriage_type'),
      marriageDetails: str(m, 'marriage_details'),
    );
  }
}

class RelationshipState {
  const RelationshipState({
    required this.id,
    this.stage = 'talking',
    this.paused = false,
    this.ended = false,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarPath,
    this.timeline = const [],
    this.gate = const GateState(),
    this.proposal,
    this.pausedBy,
    this.householdNote,
    this.householdOnHold = false,
    this.consultationStatus,
  });

  final String id;
  final String stage;
  final bool paused;
  final bool ended;
  final String? partnerId;
  final String? partnerName;
  final String? partnerAvatarPath;
  final List<TimelineEntry> timeline;
  final GateState gate;
  final StageProposal? proposal;
  final String? pausedBy;
  final String? householdNote;
  final bool householdOnHold;
  final String? consultationStatus;

  static RelationshipState fromJson(Map<String, dynamic> m) {
    final partner = mapV(m, 'partner');
    return RelationshipState(
      id: str(m, 'id') ?? str(m, 'rel_id') ?? '',
      stage: str(m, 'stage') ?? 'talking',
      paused: boolV(m, 'paused') || str(m, 'stage') == 'paused',
      ended: boolV(m, 'ended'),
      partnerId: str(partner, 'id') ?? str(m, 'partner_id'),
      partnerName: str(partner, 'display_name') ?? str(m, 'partner_name'),
      partnerAvatarPath: str(partner, 'avatar_path'),
      timeline:
          mapList(m['timeline']).map(TimelineEntry.fromJson).toList(),
      gate: GateState.fromJson(mapV(m, 'gate')),
      proposal: StageProposal.fromJson(mapV(m, 'proposal') ?? mapV(m, 'pending_proposal')),
      pausedBy: str(m, 'paused_by'),
      householdNote: str(m, 'household_note'),
      householdOnHold: str(m, 'reason') == 'household_inactive' ||
          boolV(m, 'household_on_hold'),
      consultationStatus: str(m, 'consultation_status'),
    );
  }
}

class ConsultSession {
  const ConsultSession({
    required this.id,
    this.at,
    this.minutes = 60,
    this.mode = 'in_person',
    this.location,
    this.status = 'scheduled',
    this.summary,
  });

  final String id;
  final String? at;
  final int minutes;
  final String mode;
  final String? location;
  final String status; // scheduled | held | cancelled | missed
  final String? summary;

  static ConsultSession fromJson(Map<String, dynamic> m) => ConsultSession(
        id: str(m, 'id') ?? '',
        at: str(m, 'at') ?? str(m, 'scheduled_at'),
        minutes: intV(m, 'minutes') ?? 60,
        mode: str(m, 'mode') ?? 'in_person',
        location: str(m, 'location'),
        status: str(m, 'status') ?? 'scheduled',
        summary: str(m, 'summary'),
      );
}

class ConsultationRequest {
  const ConsultationRequest({
    required this.id,
    this.relationshipId,
    this.status = 'awaiting_partner',
    this.mode,
    this.availability,
    this.note,
    this.requesterId,
    this.consultantName,
    this.sessions = const [],
    this.outcome,
    this.outcomeSummary,
    this.until,
  });

  final String id;
  final String? relationshipId;
  final String status; // awaiting_partner | awaiting_assignment | in_progress | approved | not_yet_ready | not_approved | cancelled | declined
  final String? mode;
  final String? availability;
  final String? note;
  final String? requesterId;
  final String? consultantName;
  final List<ConsultSession> sessions;
  final String? outcome;
  final String? outcomeSummary;
  final String? until;

  static ConsultationRequest fromJson(Map<String, dynamic> m) =>
      ConsultationRequest(
        id: str(m, 'id') ?? '',
        relationshipId: str(m, 'relationship_id'),
        status: str(m, 'status') ?? 'awaiting_partner',
        mode: str(m, 'mode'),
        availability: str(m, 'availability'),
        note: str(m, 'note'),
        requesterId: str(m, 'requester_id') ?? str(m, 'requested_by'),
        consultantName: str(m, 'consultant_name') ?? str(m, 'consultant'),
        sessions: mapList(m['sessions']).map(ConsultSession.fromJson).toList(),
        outcome: str(m, 'outcome') ?? str(m, 'result'),
        outcomeSummary: str(m, 'outcome_summary') ?? str(m, 'summary'),
        until: str(m, 'until'),
      );
}

class MyConsultation {
  const MyConsultation({this.eligibility, this.approvedStage, this.approvedLabel, this.request});

  final Map<String, dynamic>? eligibility;
  final String? approvedStage;
  final String? approvedLabel;
  final ConsultationRequest? request;

  static MyConsultation fromJson(Map<String, dynamic>? m) => MyConsultation(
        eligibility: mapV(m, 'eligibility'),
        approvedStage: str(m, 'approved_stage'),
        approvedLabel: str(m, 'approved_label'),
        request: ConsultationRequest.fromJson(mapV(m, 'request')),
      );
}
