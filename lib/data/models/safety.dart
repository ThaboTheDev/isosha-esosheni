import 'jsonx.dart';

class Sanction {
  const Sanction({
    required this.id,
    required this.kind,
    this.reason,
    this.startsAt,
    this.endsAt,
    this.status = 'active',
    this.canAppeal = false,
    this.appealUntil,
    this.hasAppeal = false,
  });

  final String id;
  final String kind; // warning | strike | restriction | suspension
  final String? reason;
  final String? startsAt;
  final String? endsAt;
  final String status; // active | ended | lifted | overturned
  final bool canAppeal;
  final String? appealUntil;
  final bool hasAppeal;

  String get statusLabel {
    switch (status) {
      case 'ended':
        return 'Ended';
      case 'lifted':
        return 'Lifted';
      case 'overturned':
        return 'Overturned on appeal';
      default:
        return 'Active';
    }
  }

  String get kindMeaning {
    switch (kind) {
      case 'warning':
        return 'A note on your record. Nothing changes on your account.';
      case 'strike':
        return 'Counts toward an automatic restriction or suspension if '
            'more follow.';
      case 'restriction':
        return 'You can read, but cannot contact members, post or comment.';
      case 'suspension':
        return 'You cannot use Isosha Esosheni until it ends.';
      default:
        return '';
    }
  }

  static Sanction fromJson(Map<String, dynamic> m) => Sanction(
        id: str(m, 'id') ?? '',
        kind: str(m, 'kind') ?? str(m, 'type') ?? 'warning',
        reason: str(m, 'reason'),
        startsAt: str(m, 'starts_at') ?? str(m, 'created_at'),
        endsAt: str(m, 'ends_at'),
        status: str(m, 'status') ?? 'active',
        canAppeal: boolV(m, 'can_appeal'),
        appealUntil: str(m, 'appeal_until'),
        hasAppeal: boolV(m, 'has_appeal'),
      );
}

class Standing {
  const Standing({
    this.accountStatus = 'active',
    this.activeStrikes = 0,
    this.strikeWindowDays = 90,
    this.strikesToRestrict = 3,
    this.strikesToSuspend = 5,
    this.sanctions = const [],
  });

  final String accountStatus;
  final int activeStrikes;
  final int strikeWindowDays;
  final int strikesToRestrict;
  final int strikesToSuspend;
  final List<Sanction> sanctions;

  static Standing fromJson(Map<String, dynamic>? m) => Standing(
        accountStatus: str(m, 'account_status') ?? 'active',
        activeStrikes: intV(m, 'active_strikes') ?? 0,
        strikeWindowDays: intV(m, 'strike_window_days') ?? 90,
        strikesToRestrict: intV(m, 'strikes_to_restrict') ?? 3,
        strikesToSuspend: intV(m, 'strikes_to_suspend') ?? 5,
        sanctions: mapList(m?['sanctions']).map(Sanction.fromJson).toList(),
      );
}
