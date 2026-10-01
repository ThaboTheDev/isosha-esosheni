import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backend/backend.dart';
import '../data/models/member.dart';
import '../data/models/misc.dart';
import '../data/models/profile.dart';
import '../data/repositories/account_repo.dart';
import '../data/repositories/conferences_repo.dart';
import '../data/repositories/discovery_repo.dart';
import '../data/repositories/messaging_repo.dart';
import '../core/utils/signed_url_cache.dart';

/// The one seam between UI and data. Overridden in main.dart.
final backendProvider = Provider<Backend>((ref) {
  throw StateError('backendProvider must be overridden at app start.');
});

final signedUrlCacheProvider = Provider<SignedUrlCache>(
  (ref) => SignedUrlCache(ref.watch(backendProvider)),
);

class SessionSnapshot {
  const SessionSnapshot({
    this.signedIn = false,
    this.me,
    this.aal2Required = false,
    this.loaded = false,
  });

  final bool signedIn;
  final OwnProfile? me;
  final bool aal2Required;
  final bool loaded;

  String get accountStatus => me?.accountStatus ?? 'active';
  bool get suspended =>
      accountStatus == 'suspended' || accountStatus == 'deactivated';
  bool get restricted => accountStatus == 'restricted';

  SessionSnapshot copyWith({
    bool? signedIn,
    OwnProfile? me,
    bool? aal2Required,
    bool? loaded,
  }) =>
      SessionSnapshot(
        signedIn: signedIn ?? this.signedIn,
        me: me ?? this.me,
        aal2Required: aal2Required ?? this.aal2Required,
        loaded: loaded ?? this.loaded,
      );
}

class SessionNotifier extends StateNotifier<SessionSnapshot> {
  SessionNotifier(this._backend) : super(const SessionSnapshot()) {
    _sub = _backend.authChanges.listen((_) => unawaited(reload()));
    unawaited(reload());
  }

  final Backend _backend;
  StreamSubscription<void>? _sub;

  Future<void> reload() async {
    final signedIn = _backend.signedIn;
    if (!signedIn) {
      state = const SessionSnapshot(loaded: true);
      return;
    }
    OwnProfile? me;
    try {
      final row = await _backend.selectOne('profiles');
      if (row != null) me = OwnProfile.fromJson(row);
    } catch (e) {
      debugPrint('session: profile load failed (not fatal): $e');
    }
    var aal2 = false;
    try {
      aal2 = await _backend.requiresAal2();
    } catch (_) {
      aal2 = false;
    }
    state = SessionSnapshot(
      signedIn: true,
      me: me,
      aal2Required: aal2,
      loaded: true,
    );
  }

  void patchMe(OwnProfile me) => state = state.copyWith(me: me);

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionSnapshot>((ref) {
  return SessionNotifier(ref.watch(backendProvider));
});

/// Signed avatar URL for a storage path (cached, 600 s).
final avatarUrlProvider =
    FutureProvider.autoDispose.family<String?, String?>((ref, path) async {
  if (path == null || path.isEmpty) return null;
  return ref
      .watch(signedUrlCacheProvider)
      .url('avatars', path, ttl: SignedUrlCache.avatarTtl);
});

/// Whether the member has a partner_preferences row.
final hasPreferencesProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = AccountRepository(
      ref.watch(backendProvider), ref.watch(signedUrlCacheProvider));
  return (await repo.preferences()) != null;
});

/// Provider for the app_settings keys we display.
final appSettingsProvider =
    FutureProvider.family<dynamic, String>((ref, key) async {
  final rows = await ref
      .watch(backendProvider)
      .select('app_settings', equals: {'key': key});
  if (rows.isEmpty) return null;
  return rows.first['value'];
});

/// Unread notification count for the bell badge.
final unreadNotificationsProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final backend = ref.watch(backendProvider);
  if (!backend.signedIn) return 0;
  final rows =
      await MessagingRepository(backend, ref.watch(signedUrlCacheProvider))
          .notifications(limit: 200);
  return rows.where((n) => n.unread).length;
});

/// Match summary for the bottom-bar badges.
final matchSummaryProvider =
    FutureProvider.autoDispose<MatchSummary>((ref) async {
  final backend = ref.watch(backendProvider);
  if (!backend.signedIn) return const MatchSummary();
  return DiscoveryRepository(backend).matchSummary();
});

/// The bronze "Live now" bar data.
final liveNowProvider =
    FutureProvider.autoDispose<List<LiveNowItem>>((ref) async {
  final backend = ref.watch(backendProvider);
  if (!backend.signedIn) return const [];
  return ConferencesRepository(backend).liveNow();
});

/// Announcements to display as pop-ups.
final announcementsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final backend = ref.watch(backendProvider);
  if (!backend.signedIn) return const [];
  return AccountRepository(backend, ref.watch(signedUrlCacheProvider))
      .myAnnouncements();
});

/// Permission set for role gating (consultant area, admin link, speakers).
final permissionsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final backend = ref.watch(backendProvider);
  if (!backend.signedIn) return const [];
  return AccountRepository(backend, ref.watch(signedUrlCacheProvider))
      .permissions();
});
