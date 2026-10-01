import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend.dart';

/// Real implementation backed by the shared Supabase project.
class SupabaseBackend implements Backend {
  SupabaseBackend(this._client);

  final SupabaseClient _client;

  // ---- RPC ----
  @override
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) {
    return _client.rpc(fn, params: params ?? const {});
  }

  // ---- Tables ----
  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic>? equals,
    Map<String, dynamic>? lessThan,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    var q = _client.from(table).select();
    equals?.forEach((k, v) => q = q.eq(k, v));
    lessThan?.forEach((k, v) => q = q.lt(k, v));
    PostgrestTransformBuilder<PostgrestList> t = q;
    if (orderBy != null) t = t.order(orderBy, ascending: !descending);
    if (limit != null) t = t.limit(limit);
    final rows = await t;
    return List<Map<String, dynamic>>.from(
      rows.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  @override
  Future<Map<String, dynamic>?> selectOne(
    String table, {
    Map<String, dynamic>? equals,
  }) async {
    final rows = await select(table, equals: equals, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    Map<String, dynamic>? equals,
  }) async {
    var q = _client.from(table).update(values);
    equals?.forEach((k, v) => q = q.eq(k, v));
    await q;
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> values) async {
    await _client.from(table).upsert(values);
  }

  @override
  Future<void> delete(String table, Map<String, dynamic> equals) async {
    PostgrestFilterBuilder<void> q = _client.from(table).delete();
    equals.forEach((k, v) => q = q.eq(k, v));
    await q;
  }

  // ---- Storage ----
  @override
  Future<String> signedUrl(String bucket, String path, int expiresIn) async {
    return await _client.storage.from(bucket).createSignedUrl(
          path,
          expiresIn,
        );
  }

  @override
  Future<Map<String, String>> signedUrls(
    String bucket,
    List<String> paths,
    int expiresIn,
  ) async {
    if (paths.isEmpty) return const {};
    final list = await _client.storage.from(bucket).createSignedUrls(
          paths,
          expiresIn,
        );
    final out = <String, String>{};
    for (final s in list) {
      out[s.path] = s.signedUrl;
    }
    return out;
  }

  @override
  Future<void> uploadBinary(
    String bucket,
    String path,
    Uint8List data, {
    required String contentType,
    bool upsert = false,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          data,
          fileOptions: FileOptions(contentType: contentType, upsert: upsert),
        );
  }

  @override
  Future<void> removeObjects(String bucket, List<String> paths) async {
    if (paths.isEmpty) return;
    await _client.storage.from(bucket).remove(paths);
  }

  // ---- Auth ----
  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  String? get userEmail => _client.auth.currentUser?.email;

  @override
  bool get signedIn => _client.auth.currentSession != null;

  @override
  Stream<void> get authChanges =>
      _client.auth.onAuthStateChange.map<void>((_) {});

  @override
  Future<void> refreshAuth() async {
    await _client.auth.refreshSession();
  }

  @override
  Future<AuthOutcome> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return AuthOutcome.success;
    } on AuthException catch (e) {
      return AuthOutcome(ok: false, code: _authCode(e), message: e.message);
    }
  }

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: data,
        emailRedirectTo: _redirect,
      );
      return AuthOutcome.success;
    } on AuthException catch (e) {
      return AuthOutcome(ok: false, code: _authCode(e), message: e.message);
    }
  }

  static const String _redirect = 'isosha://auth-callback';

  String _authCode(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) return 'invalid_credentials';
    if (m.contains('email not confirmed')) return 'email_not_confirmed';
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'rate_limited';
    }
    if (m.contains('password')) return 'password';
    if (m.contains('invalid otp') || m.contains('not valid')) return 'mfa';
    return 'generic';
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> requestPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email, redirectTo: _redirect);

  @override
  Future<AuthOutcome> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return AuthOutcome.success;
    } on AuthException catch (e) {
      return AuthOutcome(ok: false, code: _authCode(e), message: e.message);
    }
  }

  @override
  Future<bool> requiresAal2() async {
    final factors = await listMfaFactors();
    if (!factors.any((f) => f.verified)) return false;
    final aal = _client.auth.mfa.getAuthenticatorAssuranceLevel();
    return aal.nextLevel == AuthenticatorAssuranceLevels.aal2 &&
        aal.currentLevel != AuthenticatorAssuranceLevels.aal2;
  }

  @override
  Future<List<MfaFactor>> listMfaFactors() async {
    try {
      final res = await _client.auth.mfa.listFactors();
      return res.all
          .map((f) => MfaFactor(id: f.id, status: f.status.name))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<AuthOutcome> verifyMfa(String factorId, String code) async {
    try {
      await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code);
      return AuthOutcome.success;
    } on AuthException catch (e) {
      return AuthOutcome(ok: false, code: _authCode(e), message: e.message);
    }
  }

  @override
  Future<MfaEnrollment> enrollTotp() async {
    final res = await _client.auth.mfa.enroll(factorType: FactorType.totp);
    return MfaEnrollment(
      factorId: res.id,
      secret: res.totp?.secret ?? '',
      uri: res.totp?.uri ?? '',
    );
  }

  @override
  Future<AuthOutcome> unenrollMfa(String factorId) async {
    try {
      await _client.auth.mfa.unenroll(factorId);
      return AuthOutcome.success;
    } on AuthException catch (e) {
      return AuthOutcome(ok: false, code: _authCode(e), message: e.message);
    }
  }

  @override
  Future<AuthOutcome?> handleAuthDeepLink(Uri uri) async {
    try {
      await _client.auth.getSessionFromUrl(uri);
      return AuthOutcome.success;
    } on AuthException catch (e) {
      return AuthOutcome(ok: false, code: _authCode(e), message: e.message);
    }
  }

  // ---- Realtime ----
  @override
  CancelWatch watch(
    String table,
    WatchEvent event,
    String? filter,
    void Function(Map<String, dynamic>, Map<String, dynamic>) onEvent,
  ) {
    final type = switch (event) {
      WatchEvent.insert => PostgresChangeEvent.insert,
      WatchEvent.update => PostgresChangeEvent.update,
      WatchEvent.delete => PostgresChangeEvent.delete,
      WatchEvent.all => PostgresChangeEvent.all,
    };
    PostgresChangeFilter? pgFilter;
    if (filter != null) {
      final m = RegExp(r'^(\w+)=eq\.(.+)$').firstMatch(filter);
      if (m != null) {
        pgFilter = PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: m.group(1)!,
          value: m.group(2)!,
        );
      }
    }
    final channel = _client.channel('watch_$table$_watchSeq');
    _watchSeq++;
    channel
        .onPostgresChanges(
          event: type,
          schema: 'public',
          table: table,
          filter: pgFilter,
          callback: (payload) {
            onEvent(
              Map<String, dynamic>.from(payload.newRecord),
              Map<String, dynamic>.from(payload.oldRecord),
            );
          },
        )
        .subscribe();
    return () {
      unawaited(_client.removeChannel(channel));
    };
  }

  int _watchSeq = 0;

  @override
  Future<void> dispose() async {}
}
