import 'dart:async';

import '../../data/backend/backend.dart';

class _Entry {
  _Entry(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;
  bool get expired => DateTime.now().isAfter(expiresAt);
}

/// Signed URLs cached in memory, keyed by storage path (not the changing
/// URL). Avatars 600 s, chat media 3600 s, community/profile media 600 s —
/// the caller passes the TTL it needs; we refresh shortly before expiry.
class SignedUrlCache {
  SignedUrlCache(this._backend);

  final Backend _backend;
  final Map<String, _Entry> _cache = {};

  static const int avatarTtl = 600;
  static const int chatMediaTtl = 3600;
  static const int mediaTtl = 600;

  Future<String?> url(String bucket, String? path, {int ttl = mediaTtl}) async {
    if (path == null || path.isEmpty) return null;
    final key = '$bucket/$path';
    final hit = _cache[key];
    if (hit != null && !hit.expired) return hit.url;
    final url = await _backend.signedUrl(bucket, path, ttl);
    // Refresh a bit before the real expiry.
    _cache[key] = _Entry(
      url,
      DateTime.now().add(Duration(seconds: (ttl * 0.9).round())),
    );
    return url;
  }

  Future<Map<String, String>> urls(
    String bucket,
    List<String> paths, {
    int ttl = mediaTtl,
  }) async {
    final out = <String, String>{};
    final missing = <String>[];
    for (final p in paths) {
      final key = '$bucket/$p';
      final hit = _cache[key];
      if (hit != null && !hit.expired) {
        out[p] = hit.url;
      } else {
        missing.add(p);
      }
    }
    if (missing.isNotEmpty) {
      final fresh = await _backend.signedUrls(bucket, missing, ttl);
      fresh.forEach((p, url) {
        _cache['$bucket/$p'] = _Entry(
          url,
          DateTime.now().add(Duration(seconds: (ttl * 0.9).round())),
        );
        out[p] = url;
      });
    }
    return out;
  }

  void invalidate(String bucket, String path) =>
      _cache.remove('$bucket/$path');
}
