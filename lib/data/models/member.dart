import 'jsonx.dart';

/// The discovery gate object.
class Gate {
  const Gate({
    required this.ok,
    this.reason,
    this.status,
    this.completion,
    this.minCompletion,
    this.visibleToOthers,
  });

  final bool ok;

  /// 'not_member' | 'inactive' | 'stage'
  final String? reason;
  final String? status;
  final int? completion;
  final int? minCompletion;
  final bool? visibleToOthers;

  static Gate fromJson(Map<String, dynamic>? m) => Gate(
        ok: boolV(m, 'ok'),
        reason: str(m, 'reason'),
        status: str(m, 'status'),
        completion: intV(m, 'completion'),
        minCompletion: intV(m, 'min_completion'),
        visibleToOthers: m == null ? null : (m['visible_to_others'] as bool?),
      );
}

class HouseholdInfo {
  const HouseholdInfo({required this.wives, this.seeking = true});
  final int wives;
  final bool seeking;

  static HouseholdInfo? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return HouseholdInfo(
      wives: intV(m, 'wives') ?? 0,
      seeking: boolV(m, 'seeking', true),
    );
  }
}

/// What the guarded member endpoints return for a card.
class MemberCardData {
  const MemberCardData({
    required this.id,
    required this.displayName,
    this.age,
    this.city,
    this.province,
    this.profession,
    this.avatarPath,
    this.bio,
    this.note,
    this.intentions = const [],
    this.relationshipStatus,
    this.household,
    this.isDemo = false,
    this.score,
    this.reasons = const [],
    this.saved = false,
    this.liked = false,
    this.matched = false,
    this.interestSent = false,
    this.interestReceived,
    this.hasVideo = false,
    this.videoPath,
  });

  final String id;
  final String displayName;
  final int? age;
  final String? city;
  final String? province;
  final String? profession;
  final String? avatarPath;
  final String? bio;
  final String? note;
  final List<String> intentions;
  final String? relationshipStatus;
  final HouseholdInfo? household;
  final bool isDemo;
  final int? score;
  final List<String> reasons;
  final bool saved;
  final bool liked;
  final bool matched;
  final bool interestSent;
  final String? interestReceived;
  final bool hasVideo;
  final String? videoPath;

  static MemberCardData fromJson(Map<String, dynamic> m) => MemberCardData(
        id: str(m, 'id') ?? '',
        displayName: str(m, 'display_name') ?? str(m, 'full_name') ?? 'Member',
        age: intV(m, 'age'),
        city: str(m, 'city'),
        province: str(m, 'province'),
        profession: str(m, 'profession'),
        avatarPath: str(m, 'avatar_path'),
        bio: str(m, 'bio') ?? str(m, 'bio_about'),
        note: str(m, 'note'),
        intentions: strList(m, 'intentions'),
        relationshipStatus: str(m, 'relationship_status'),
        household: HouseholdInfo.fromJson(mapV(m, 'household')),
        isDemo: boolV(m, 'is_demo'),
        score: intV(m, 'score'),
        reasons: strList(m, 'reasons'),
        saved: boolV(m, 'saved'),
        liked: boolV(m, 'liked'),
        matched: boolV(m, 'matched'),
        interestSent: boolV(m, 'interest_sent'),
        interestReceived: str(m, 'interest_received'),
        hasVideo: boolV(m, 'has_video'),
        videoPath: str(m, 'video_path'),
      );
}

class Compatibility {
  const Compatibility({this.score, this.reasons = const [], this.disclaimer});
  final int? score;
  final List<String> reasons;
  final String? disclaimer;

  static Compatibility fromJson(Map<String, dynamic>? m) => Compatibility(
        score: intV(m, 'score'),
        reasons: strList(m, 'reasons'),
        disclaimer: str(m, 'disclaimer'),
      );
}

class MatchSummary {
  const MatchSummary({
    this.interestsReceived = 0,
    this.interestsSent = 0,
    this.matches = 0,
    this.likesReceived = 0,
  });

  final int interestsReceived;
  final int interestsSent;
  final int matches;
  final int likesReceived;

  static MatchSummary fromJson(Map<String, dynamic>? m) => MatchSummary(
        interestsReceived: intV(m, 'interests_received') ?? 0,
        interestsSent: intV(m, 'interests_sent') ?? 0,
        matches: intV(m, 'matches') ?? 0,
        likesReceived: intV(m, 'likes_received') ?? 0,
      );
}
