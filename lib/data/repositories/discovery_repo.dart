import '../backend/backend.dart';
import '../models/member.dart';

class RecommendationsResult {
  const RecommendationsResult({
    required this.gate,
    required this.rows,
    this.disclaimer,
  });
  final Gate gate;
  final List<MemberCardData> rows;
  final String? disclaimer;
}

class SearchResult {
  const SearchResult({
    required this.gate,
    required this.rows,
    required this.total,
    required this.pageSize,
  });
  final Gate gate;
  final List<MemberCardData> rows;
  final int total;
  final int pageSize;
}

class ConnectionsResult {
  const ConnectionsResult({
    this.received = const [],
    this.sent = const [],
    this.matches = const [],
    this.saved = const [],
    this.likedMe = const [],
    this.hidden = const [],
    this.history = const [],
  });
  final List<MemberCardData> received;
  final List<MemberCardData> sent;
  final List<MemberCardData> matches;
  final List<MemberCardData> saved;
  final List<MemberCardData> likedMe;
  final List<MemberCardData> hidden;
  final List<MemberCardData> history;

  static ConnectionsResult fromJson(dynamic v) {
    final m = v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};
    List<MemberCardData> key(String k) => (m[k] as List? ?? [])
        .whereType<Map>()
        .map((e) => MemberCardData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return ConnectionsResult(
      received: key('received'),
      sent: key('sent'),
      matches: key('matches'),
      saved: key('saved'),
      likedMe: key('liked_me'),
      hidden: key('hidden'),
      history: key('history'),
    );
  }
}

class DiscoveryRepository {
  DiscoveryRepository(this._b);
  final Backend _b;

  Future<RecommendationsResult> recommendations({int lim = 12, int off = 0}) async {
    final res = await _b.rpc('get_recommendations', params: {'lim': lim, 'off': off});
    final m = Map<String, dynamic>.from(res as Map);
    return RecommendationsResult(
      gate: Gate.fromJson(Map<String, dynamic>.from(m['gate'] ?? {})),
      rows: (m['rows'] as List? ?? [])
          .whereType<Map>()
          .map((e) => MemberCardData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      disclaimer: m['disclaimer'] as String?,
    );
  }

  Future<SearchResult> search(Map<String, dynamic> filters, {int page = 1}) async {
    final res = await _b
        .rpc('search_members', params: {'f': filters, 'page': page});
    final m = Map<String, dynamic>.from(res as Map);
    return SearchResult(
      gate: Gate.fromJson(Map<String, dynamic>.from(m['gate'] ?? {})),
      rows: (m['rows'] as List? ?? [])
          .whereType<Map>()
          .map((e) => MemberCardData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: (m['total'] as num?)?.toInt() ?? 0,
      pageSize: (m['page_size'] as num?)?.toInt() ?? 10,
    );
  }

  Future<MemberCardData> memberProfile(String target) async {
    final res = await _b
        .rpc('get_member_profile_guarded', params: {'target': target});
    return MemberCardData.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<Compatibility> compatibility(String target) async {
    final res = await _b.rpc('get_compatibility', params: {'c': target});
    return Compatibility.fromJson(Map<String, dynamic>.from(res as Map? ?? {}));
  }

  Future<void> sendInterest(String target, {String? note}) =>
      _b.rpc('send_interest', params: {
        'target': target,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> respondInterest(String interest, bool accept) =>
      _b.rpc('respond_interest', params: {'interest': interest, 'accept': accept});

  Future<void> withdrawInterest(String interest) =>
      _b.rpc('withdraw_interest', params: {'interest': interest});

  Future<bool> toggleLike(String target) async =>
      (await _b.rpc('toggle_like', params: {'target': target})) == true;

  Future<bool> toggleSave(String target) async =>
      (await _b.rpc('toggle_save', params: {'target': target})) == true;

  Future<void> setPass(String target, bool passed) =>
      _b.rpc('set_pass', params: {'target': target, 'passed': passed});

  Future<void> block(String target) =>
      _b.rpc('block_member', params: {'target': target});

  Future<void> unblock(String target) =>
      _b.rpc('unblock_member', params: {'target': target});

  Future<List<MemberCardData>> blocked() async {
    final res = await _b.rpc('my_blocked');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => MemberCardData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ConnectionsResult> connections() async =>
      ConnectionsResult.fromJson(await _b.rpc('my_connections'));

  Future<MatchSummary> matchSummary() async =>
      MatchSummary.fromJson(
          (await _b.rpc('my_match_summary') as Map?)?.cast<String, dynamic>());

  Future<void> endMatch(String match) =>
      _b.rpc('end_match', params: {'match': match});

  Future<void> reportMember(
    String target,
    String category,
    String details, {
    String? conv,
    String? msg,
  }) =>
      _b.rpc('report_member', params: {
        'target': target,
        'category': category,
        'details': details,
        if (conv != null) 'conv': conv,
        if (msg != null) 'msg': msg,
      });
}
