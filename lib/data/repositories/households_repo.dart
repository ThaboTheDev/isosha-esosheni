import '../backend/backend.dart';
import '../models/member.dart';

class HouseholdResult {
  const HouseholdResult({
    required this.eligibility,
    this.asHead = false,
    this.wivesOnRecord = const [],
    this.household,
  });
  final Map<String, dynamic> eligibility;
  final bool asHead;
  final List<Map<String, dynamic>> wivesOnRecord;
  final Map<String, dynamic>? household;

  static HouseholdResult fromJson(dynamic v) {
    final m = v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};
    return HouseholdResult(
      eligibility:
          Map<String, dynamic>.from(m['eligibility'] ?? const <String, dynamic>{}),
      asHead: m['as_head'] == true,
      wivesOnRecord: (m['wives_on_record'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      household: m['household'] is Map
          ? Map<String, dynamic>.from(m['household'] as Map)
          : null,
    );
  }
}

class HouseholdsRepository {
  HouseholdsRepository(this._b);
  final Backend _b;

  Future<HouseholdResult> myHousehold() async =>
      HouseholdResult.fromJson(await _b.rpc('my_household'));

  Future<Map<String, dynamic>> eligibility() async {
    final res = await _b.rpc('household_eligibility');
    return res is Map ? Map<String, dynamic>.from(res) : const {};
  }

  Future<String> saveHousehold({
    required String about,
    required String seeking,
    required int children,
    required String province,
    required String city,
  }) async {
    final id = await _b.rpc('save_household', params: {
      'about': about,
      'seeking': seeking,
      'children': children,
      'province': province,
      'city': city,
    });
    return id.toString();
  }

  Future<void> submitHousehold() => _b.rpc('submit_household');

  Future<void> respondConsent(String hh, bool give, {String? note}) =>
      _b.rpc('respond_household_consent', params: {
        'hh': hh,
        'give': give,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> withdrawConsent(String hh, {String? note}) =>
      _b.rpc('withdraw_household_consent', params: {
        'hh': hh,
        if (note != null && note.isNotEmpty) 'note': note,
      });

  Future<void> closeHousehold(String hh, {String? reason}) =>
      _b.rpc('close_household', params: {
        'hh': hh,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

  Future<List<MemberCardData>> directory() async {
    final res = await _b.rpc('household_directory');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => MemberCardData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<MemberCardData>> candidates() async {
    final res = await _b.rpc('household_candidates');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => MemberCardData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> sendInterest(String target, {String? note}) =>
      _b.rpc('send_household_interest', params: {
        'target': target,
        if (note != null && note.isNotEmpty) 'note': note,
      });
}
