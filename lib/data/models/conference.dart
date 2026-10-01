import 'jsonx.dart';

class ConferenceSpeaker {
  const ConferenceSpeaker({this.name, this.title, this.bio});
  final String? name;
  final String? title;
  final String? bio;

  static ConferenceSpeaker fromJson(Map<String, dynamic> m) =>
      ConferenceSpeaker(
        name: str(m, 'name') ?? str(m, 'full_name'),
        title: str(m, 'title'),
        bio: str(m, 'bio'),
      );
}

class ConferenceQuestion {
  const ConferenceQuestion({
    required this.id,
    required this.body,
    this.anonymous = false,
    this.answered = false,
  });
  final String id;
  final String body;
  final bool anonymous;
  final bool answered;

  static ConferenceQuestion fromJson(Map<String, dynamic> m) =>
      ConferenceQuestion(
        id: str(m, 'id') ?? '',
        body: str(m, 'body') ?? '',
        anonymous: boolV(m, 'anonymous'),
        answered: boolV(m, 'answered'),
      );
}

class ConferenceSession {
  const ConferenceSession({
    required this.id,
    this.title,
    this.description,
    this.startsAt,
    this.endsAt,
    this.speaker,
    this.liveUrl,
    this.recordingUrl,
    this.questions = const [],
  });

  final String id;
  final String? title;
  final String? description;
  final String? startsAt;
  final String? endsAt;
  final ConferenceSpeaker? speaker;
  final String? liveUrl;
  final String? recordingUrl;
  final List<ConferenceQuestion> questions;

  static ConferenceSession fromJson(Map<String, dynamic> m) =>
      ConferenceSession(
        id: str(m, 'id') ?? '',
        title: str(m, 'title'),
        description: str(m, 'description'),
        startsAt: str(m, 'starts_at') ?? str(m, 'start_at'),
        endsAt: str(m, 'ends_at') ?? str(m, 'end_at'),
        speaker: ConferenceSpeaker.fromJson(mapV(m, 'speaker')),
        liveUrl: str(m, 'live_url'),
        recordingUrl: str(m, 'recording_url'),
        questions:
            mapList(m['my_questions'] ?? m['questions'])
                .map(ConferenceQuestion.fromJson)
                .toList(),
      );
}

class ConferenceSummary {
  const ConferenceSummary({
    required this.id,
    this.kind = 'Conference',
    this.title = '',
    this.summary,
    this.format,
    this.city,
    this.province,
    this.startsAt,
    this.endsAt,
    this.capacity,
    this.seatsLeft,
    this.audience,
    this.registration,
    this.speakers = const [],
    this.recordings = 0,
  });

  final String id;
  final String kind;
  final String title;
  final String? summary;
  final String? format;
  final String? city;
  final String? province;
  final String? startsAt;
  final String? endsAt;
  final int? capacity;
  final int? seatsLeft;
  final String? audience;
  final String? registration; // registered | waitlisted
  final List<ConferenceSpeaker> speakers;
  final int recordings;

  static ConferenceSummary fromJson(Map<String, dynamic> m) =>
      ConferenceSummary(
        id: str(m, 'id') ?? '',
        kind: str(m, 'kind') ?? 'Conference',
        title: str(m, 'title') ?? '',
        summary: str(m, 'summary'),
        format: str(m, 'format'),
        city: str(m, 'city'),
        province: str(m, 'province'),
        startsAt: str(m, 'starts_at'),
        endsAt: str(m, 'ends_at'),
        capacity: intV(m, 'capacity'),
        seatsLeft: intV(m, 'seats_left'),
        audience: str(m, 'audience'),
        registration: str(m, 'my_registration') ?? str(m, 'registration'),
        speakers: mapList(m['speakers']).map(ConferenceSpeaker.fromJson).toList(),
        recordings: intV(m, 'recordings') ?? 0,
      );
}

class ConferenceDetail extends ConferenceSummary {
  const ConferenceDetail({
    required super.id,
    super.kind,
    super.title,
    super.summary,
    super.format,
    super.city,
    super.province,
    super.startsAt,
    super.endsAt,
    super.capacity,
    super.seatsLeft,
    super.audience,
    super.registration,
    super.speakers,
    super.recordings,
    this.description,
    this.venue,
    this.registrationClosesAt,
    this.cancelledReason,
    this.sessions = const [],
    this.waitlistPosition,
  });

  final String? description;
  final String? venue;
  final String? registrationClosesAt;
  final String? cancelledReason;
  final List<ConferenceSession> sessions;
  final int? waitlistPosition;

  static ConferenceDetail fromJson(Map<String, dynamic> m) {
    final s = ConferenceSummary.fromJson(m);
    return ConferenceDetail(
      id: s.id,
      kind: s.kind,
      title: s.title,
      summary: s.summary,
      format: s.format,
      city: s.city,
      province: s.province,
      startsAt: s.startsAt,
      endsAt: s.endsAt,
      capacity: s.capacity,
      seatsLeft: s.seatsLeft,
      audience: s.audience,
      registration: s.registration,
      speakers: s.speakers,
      recordings: s.recordings,
      description: str(m, 'description'),
      venue: str(m, 'venue'),
      registrationClosesAt: str(m, 'registration_closes_at'),
      cancelledReason: str(m, 'cancelled_reason') ?? str(m, 'cancellation_reason'),
      sessions: mapList(m['sessions']).map(ConferenceSession.fromJson).toList(),
      waitlistPosition: intV(m, 'waitlist_position'),
    );
  }
}

class LiveChatMessage {
  const LiveChatMessage({
    required this.id,
    this.authorId,
    this.authorName,
    required this.body,
    required this.createdAt,
    this.speaker = false,
  });

  final String id;
  final String? authorId;
  final String? authorName;
  final String body;
  final String createdAt;
  final bool speaker;

  static LiveChatMessage fromJson(Map<String, dynamic> m) => LiveChatMessage(
        id: str(m, 'id') ?? '',
        authorId: str(m, 'author_id') ?? str(m, 'user_id'),
        authorName: str(m, 'author_name') ?? str(m, 'display_name'),
        body: str(m, 'body') ?? '',
        createdAt: str(m, 'created_at') ?? DateTime.now().toIso8601String(),
        speaker: boolV(m, 'is_speaker') || boolV(m, 'speaker'),
      );
}

class LiveRoom {
  const LiveRoom({
    required this.sessionId,
    this.title,
    this.conferenceId,
    this.conferenceTitle,
    this.status = 'scheduled',
    this.kind,
    this.allowed = false,
    this.canRun = false,
    this.url,
    this.room,
    this.jitsiDomain,
    this.recordingUrl,
    this.chat = const [],
  });

  final String sessionId;
  final String? title;
  final String? conferenceId;
  final String? conferenceTitle;
  final String status; // scheduled | live | ended
  final String? kind; // youtube | jitsi | zoom | link | null
  final bool allowed;
  final bool canRun;
  final String? url;
  final String? room;
  final String? jitsiDomain;
  final String? recordingUrl;
  final List<LiveChatMessage> chat;

  static LiveRoom fromJson(Map<String, dynamic> m) {
    final conf = mapV(m, 'conference');
    return LiveRoom(
      sessionId: str(m, 'session_id') ?? str(m, 'id') ?? '',
      title: str(m, 'title'),
      conferenceId: str(m, 'conference_id') ?? str(conf, 'id'),
      conferenceTitle: str(m, 'conference_title') ?? str(conf, 'title'),
      status: str(m, 'status') ?? 'scheduled',
      kind: str(m, 'kind'),
      allowed: boolV(m, 'allowed'),
      canRun: boolV(m, 'can_run'),
      url: str(m, 'url') ?? str(m, 'live_url'),
      room: str(m, 'room'),
      jitsiDomain: str(m, 'jitsi_domain'),
      recordingUrl: str(m, 'recording_url'),
      chat: mapList(m['chat']).map(LiveChatMessage.fromJson).toList(),
    );
  }

  LiveRoom copyWith({String? status, List<LiveChatMessage>? chat}) => LiveRoom(
        sessionId: sessionId,
        title: title,
        conferenceId: conferenceId,
        conferenceTitle: conferenceTitle,
        status: status ?? this.status,
        kind: kind,
        allowed: allowed,
        canRun: canRun,
        url: url,
        room: room,
        jitsiDomain: jitsiDomain,
        recordingUrl: recordingUrl,
        chat: chat ?? this.chat,
      );
}

class SpeakingSession {
  const SpeakingSession({
    required this.id,
    this.title,
    this.conferenceTitle,
    this.description,
    this.liveUrl,
    this.recordingUrl,
    this.status,
  });

  final String id;
  final String? title;
  final String? conferenceTitle;
  final String? description;
  final String? liveUrl;
  final String? recordingUrl;
  final String? status;

  static SpeakingSession fromJson(Map<String, dynamic> m) => SpeakingSession(
        id: str(m, 'id') ?? '',
        title: str(m, 'title'),
        conferenceTitle: str(m, 'conference_title'),
        description: str(m, 'description'),
        liveUrl: str(m, 'live_url'),
        recordingUrl: str(m, 'recording_url'),
        status: str(m, 'status'),
      );
}
