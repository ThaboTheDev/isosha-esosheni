import 'dart:typed_data';

import '../../core/utils/signed_url_cache.dart';
import '../backend/backend.dart';
import '../models/profile.dart';

class AccountRepository {
  AccountRepository(this._b, this._cache);
  final Backend _b;
  final SignedUrlCache _cache;

  Future<OwnProfile> myProfile() async {
    final row = await _b.selectOne('profiles');
    return OwnProfile.fromJson(row ?? const {});
  }

  /// Updates only the member-editable columns; the DB trigger rejects
  /// protected columns, and we never send them.
  Future<OwnProfile> updateProfile(
      String userId, Map<String, dynamic> fields) async {
    final cleaned = Map<String, dynamic>.from(fields);
    cleaned.removeWhere((k, v) => _protected.contains(k));
    await _b.update('profiles', cleaned, equals: {'id': userId});
    return myProfile();
  }

  static const Set<String> _protected = {
    'membership_status',
    'account_status',
    'is_demo',
    'completion_percent',
    'visible_to_others',
  };

  Future<PartnerPreferences?> preferences() async {
    final rows = await _b.select('partner_preferences', limit: 1);
    return rows.isEmpty ? null : PartnerPreferences.fromJson(rows.first);
  }

  Future<List<Map<String, dynamic>>> myAnnouncements() async {
    final res = await _b.rpc('my_announcements');
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<void> dismissAnnouncement(String id) =>
      _b.rpc('dismiss_announcement', params: {'ann': id});

  Future<void> savePreferences(PartnerPreferences p, String userId) =>
      _b.upsert('partner_preferences', {...p.toJson(), 'user_id': userId});

  Future<List<FieldVisibility>> fieldVisibility() async {
    final defaults = await _b.select('profile_field_defaults');
    final own = await _b.select('profile_field_visibility');
    final ownByKey = {for (final r in own) r['field_key']: r['visibility']};
    final defByKey = {
      for (final r in defaults) r['field_key']: r['default_visibility'],
    };
    return [
      for (final f in privacyFields)
        f.copyWith(
          visibility: (ownByKey[f.key] ?? defByKey[f.key] ?? 'all').toString(),
        ),
    ];
  }

  Future<void> setVisibility(String userId, String fieldKey, String visibility) =>
      _b.upsert('profile_field_visibility', {
        'user_id': userId,
        'field_key': fieldKey,
        'visibility': visibility,
      });

  // ---- Media uploads ----
  Future<String> uploadAvatar(String userId, Uint8List bytes,
      {required String ext, required String contentType}) async {
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _b.uploadBinary('avatars', path, bytes, contentType: contentType);
    return path;
  }

  Future<String> uploadProfileVideo(String userId, Uint8List bytes,
      {required String ext, required String contentType}) async {
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _b.uploadBinary('profile-videos', path, bytes,
        contentType: contentType);
    return path;
  }

  Future<String?> avatarUrl(String? path) =>
      _cache.url('avatars', path, ttl: SignedUrlCache.avatarTtl);

  Future<String?> videoUrl(String? path) =>
      _cache.url('profile-videos', path, ttl: SignedUrlCache.mediaTtl);

  Future<void> removeObjects(String bucket, List<String> paths) =>
      _b.removeObjects(bucket, paths);

  // ---- Export ----
  Future<Map<String, dynamic>> exportMyData() async {
    final res = await _b.rpc('export_my_data');
    return res is Map ? Map<String, dynamic>.from(res) : const {};
  }

  Future<List<String>> permissions() async {
    final res = await _b.rpc('my_permissions');
    return res is List ? res.whereType<String>().toList() : const [];
  }
}
