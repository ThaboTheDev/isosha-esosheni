import '../backend/backend.dart';
import '../models/conference.dart';
import '../models/misc.dart';

class ConferencesRepository {
  ConferencesRepository(this._b);
  final Backend _b;

  Future<List<ConferenceSummary>> list() async {
    final res = await _b.rpc('conference_list');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => ConferenceSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ConferenceDetail> detail(String conf) async {
    final res = await _b.rpc('conference_detail', params: {'conf': conf});
    return ConferenceDetail.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<String> register(String conf) async {
    final res = await _b.rpc('register_conference', params: {'conf': conf});
    return res?.toString() ?? 'registered';
  }

  Future<void> cancelRegistration(String conf) =>
      _b.rpc('cancel_registration', params: {'conf': conf});

  Future<String> askQuestion(String session, String body,
          {bool anonymous = false}) async =>
      (await _b.rpc('ask_question', params: {
        'session': session,
        'body': body,
        'anonymous': anonymous,
      }))
          .toString();

  Future<List<LiveNowItem>> liveNow() async {
    final res = await _b.rpc('live_now');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => LiveNowItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<LiveRoom> liveRoom(String session) async {
    final res = await _b.rpc('live_room', params: {'session': session});
    return LiveRoom.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<String> sendLiveChat(String session, String body) async =>
      (await _b.rpc('send_live_chat', params: {
        'session': session,
        'body': body,
      }))
          .toString();

  Future<void> hideLiveChat(String msg) =>
      _b.rpc('hide_live_chat', params: {'msg': msg});

  CancelWatch watchLiveChat(
          String session, void Function(LiveChatMessage) onMessage) =>
      _b.watch('conference_chat', WatchEvent.insert, 'session_id=eq.$session',
          (rec, _) {
        if (rec['hidden'] == true) return;
        onMessage(LiveChatMessage.fromJson(rec));
      });

  // Speaker tools (role-gated)
  Future<List<SpeakingSession>> mySpeaking() async {
    final res = await _b.rpc('my_speaking');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => SpeakingSession.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> updateMySession(
    String session, {
    String? description,
    String? liveUrl,
    String? recordingUrl,
  }) =>
      _b.rpc('update_my_session', params: {
        'session': session,
        'description': description,
        'live_url': liveUrl,
        'recording_url': recordingUrl,
      });

  Future<void> goLive(String session, String kind, {String? url}) =>
      _b.rpc('go_live', params: {
        'session': session,
        'kind': kind,
        if (url != null) 'url': url,
      });

  Future<void> endLive(String session, {String? recording}) =>
      _b.rpc('end_live', params: {
        'session': session,
        if (recording != null) 'recording': recording,
      });
}
