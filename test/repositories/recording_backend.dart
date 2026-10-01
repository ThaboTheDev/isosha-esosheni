import 'dart:typed_data';

import 'package:isosha_esosheni/data/backend/backend.dart';
import 'package:isosha_esosheni/data/backend/fake_backend.dart';

/// Wraps the in-memory backend and records every RPC call with its exact
/// parameter keys, so repository tests can assert the contract.
class RecordingBackend implements Backend {
  RecordingBackend(this.inner);

  final FakeBackend inner;
  final List<RecordedRpc> calls = [];

  List<String> paramKeys(String fn) =>
      calls.where((c) => c.fn == fn).map((c) {
        return (c.params?.keys.toList()..sort()).join(',');
      }).toList();

  @override
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    calls.add(RecordedRpc(fn, params));
    return inner.rpc(fn, params: params);
  }

  // ---- everything else forwards ----
  @override
  Future<List<Map<String, dynamic>>> select(String table,
          {Map<String, dynamic>? equals,
          Map<String, dynamic>? lessThan,
          int? limit,
          String? orderBy,
          bool descending = false}) =>
      inner.select(table,
          equals: equals,
          lessThan: lessThan,
          limit: limit,
          orderBy: orderBy,
          descending: descending);

  @override
  Future<Map<String, dynamic>?> selectOne(String table,
          {Map<String, dynamic>? equals}) =>
      inner.selectOne(table, equals: equals);

  @override
  Future<void> update(String table, Map<String, dynamic> values,
      {Map<String, dynamic>? equals}) {
    calls.add(RecordedRpc('update', values));
    return inner.update(table, values, equals: equals);
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> values) {
    calls.add(RecordedRpc('upsert', values));
    return inner.upsert(table, values);
  }

  @override
  Future<void> delete(String table, Map<String, dynamic> equals) =>
      inner.delete(table, equals);

  @override
  Future<String> signedUrl(String bucket, String path, int expiresIn) =>
      inner.signedUrl(bucket, path, expiresIn);

  @override
  Future<Map<String, String>> signedUrls(
          String bucket, List<String> paths, int expiresIn) =>
      inner.signedUrls(bucket, paths, expiresIn);

  @override
  Future<void> uploadBinary(String bucket, String path, Uint8List data,
          {required String contentType, bool upsert = false}) =>
      inner.uploadBinary(bucket, path, data,
          contentType: contentType, upsert: upsert);

  @override
  Future<void> removeObjects(String bucket, List<String> paths) =>
      inner.removeObjects(bucket, paths);

  @override
  String? get userId => inner.userId;

  @override
  String? get userEmail => inner.userEmail;

  @override
  bool get signedIn => inner.signedIn;

  @override
  Stream<void> get authChanges => inner.authChanges;

  @override
  Future<void> refreshAuth() => inner.refreshAuth();

  @override
  Future<AuthOutcome> signIn(String email, String password) =>
      inner.signIn(email, password);

  @override
  Future<AuthOutcome> signUp(
          {required String email,
          required String password,
          required Map<String, dynamic> data}) =>
      inner.signUp(email: email, password: password, data: data);

  @override
  Future<void> signOut() => inner.signOut();

  @override
  Future<void> requestPasswordReset(String email) =>
      inner.requestPasswordReset(email);

  @override
  Future<AuthOutcome> updatePassword(String newPassword) =>
      inner.updatePassword(newPassword);

  @override
  Future<bool> requiresAal2() => inner.requiresAal2();

  @override
  Future<List<MfaFactor>> listMfaFactors() => inner.listMfaFactors();

  @override
  Future<AuthOutcome> verifyMfa(String factorId, String code) =>
      inner.verifyMfa(factorId, code);

  @override
  Future<MfaEnrollment> enrollTotp() => inner.enrollTotp();

  @override
  Future<AuthOutcome> unenrollMfa(String factorId) =>
      inner.unenrollMfa(factorId);

  @override
  Future<AuthOutcome?> handleAuthDeepLink(Uri uri) =>
      inner.handleAuthDeepLink(uri);

  @override
  CancelWatch watch(String table, WatchEvent event, String? filter,
          void Function(Map<String, dynamic>, Map<String, dynamic>) onEvent) =>
      inner.watch(table, event, filter, onEvent);

  @override
  Future<void> dispose() => inner.dispose();
}

class RecordedRpc {
  RecordedRpc(this.fn, this.params);
  final String fn;
  final Map<String, dynamic>? params;
}
