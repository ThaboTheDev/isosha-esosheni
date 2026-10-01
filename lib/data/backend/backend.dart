import 'dart:typed_data';

/// Everything the repositories may need, behind one seam.
///
/// The UI never talks to Supabase directly: it goes through repositories,
/// and repositories only use this interface. [SupabaseBackend] is the real
/// implementation; [FakeBackend] is an in-memory demo/test double, so the
/// app can be developed and demoed without credentials and switching to
/// Supabase is a one-line change in `core/providers.dart`.
abstract class Backend {
  // ---- RPC (security definer functions on Postgres) ----
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params});

  // ---- Direct table access (RLS-protected reads/writes) ----
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic>? equals,
    Map<String, dynamic>? lessThan,
    int? limit,
    String? orderBy,
    bool descending = false,
  });

  Future<Map<String, dynamic>?> selectOne(
    String table, {
    Map<String, dynamic>? equals,
  });

  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    Map<String, dynamic>? equals,
  });

  Future<void> upsert(String table, Map<String, dynamic> values);

  Future<void> delete(String table, Map<String, dynamic> equals);

  // ---- Storage (private buckets + signed URLs) ----
  Future<String> signedUrl(String bucket, String path, int expiresIn);
  Future<Map<String, String>> signedUrls(
      String bucket, List<String> paths, int expiresIn);
  Future<void> uploadBinary(
    String bucket,
    String path,
    Uint8List data, {
    required String contentType,
    bool upsert = false,
  });
  Future<void> removeObjects(String bucket, List<String> paths);

  // ---- Auth ----
  String? get userId;
  String? get userEmail;
  bool get signedIn;
  Stream<void> get authChanges;
  Future<void> refreshAuth();
  Future<AuthOutcome> signIn(String email, String password);
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  });
  Future<void> signOut();
  Future<void> requestPasswordReset(String email);
  Future<AuthOutcome> updatePassword(String newPassword);

  /// True when an enrolled factor exists and the session is not AAL2 yet.
  Future<bool> requiresAal2();
  Future<List<MfaFactor>> listMfaFactors();
  Future<AuthOutcome> verifyMfa(String factorId, String code);
  Future<MfaEnrollment> enrollTotp();
  Future<AuthOutcome> unenrollMfa(String factorId);

  /// Handles isosha:// deep links (email confirmation / recovery).
  Future<AuthOutcome?> handleAuthDeepLink(Uri uri);

  // ---- Realtime ----
  /// Subscribes to postgres_changes on [table] filtered by [filter]
  /// (e.g. `conversation_id=eq.<id>`). Returns a cancel function.
  CancelWatch watch(
    String table,
    WatchEvent event,
    String? filter,
    void Function(Map<String, dynamic> newRecord, Map<String, dynamic> oldRecord)
        onEvent,
  );

  Future<void> dispose();
}

typedef CancelWatch = void Function();

enum WatchEvent { insert, update, delete, all }

class AuthOutcome {
  const AuthOutcome({this.ok = false, this.code, this.message});
  final bool ok;
  final String? code;
  final String? message;

  static const AuthOutcome success = AuthOutcome(ok: true);
}

class MfaFactor {
  const MfaFactor({required this.id, this.status = 'verified'});
  final String id;
  final String status;
  bool get verified => status == 'verified';
}

class MfaEnrollment {
  const MfaEnrollment({
    required this.factorId,
    required this.secret,
    required this.uri,
  });
  final String factorId;
  final String secret;
  final String uri;
}
