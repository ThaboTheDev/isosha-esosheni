import 'dart:typed_data';

import '../../core/utils/signed_url_cache.dart';
import '../backend/backend.dart';
import '../models/community.dart';

class FeedResult {
  const FeedResult({required this.rows, this.nextBefore});
  final List<Post> rows;
  final String? nextBefore;
}

class CommunityRepository {
  CommunityRepository(this._b, this._cache);
  final Backend _b;
  final SignedUrlCache _cache;

  Future<FeedResult> feed({String? before, int lim = 20, String? author}) async {
    final res = Map<String, dynamic>.from(await _b.rpc('get_feed', params: {
      if (before != null) 'before': before,
      'lim': lim,
      if (author != null) 'author': author,
    }) as Map);
    final rows = (res['rows'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return FeedResult(rows: rows, nextBefore: res['next_before'] as String?);
  }

  Future<Post> post(String id) async {
    final res = await _b.rpc('get_post', params: {'post': id});
    return Post.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<StoryGroup>> storyRing() async {
    final res = await _b.rpc('story_ring');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => StoryGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String> createPost(String body, {String? mediaPath}) async {
    final id = await _b.rpc('create_post', params: {
      'body': body,
      if (mediaPath != null) 'media': mediaPath,
    });
    return id.toString();
  }

  Future<void> editPost(String post, String body) =>
      _b.rpc('edit_post', params: {'post': post, 'body': body});

  Future<void> deletePost(String post) =>
      _b.rpc('delete_post', params: {'post': post});

  Future<String> addComment(String post, String body) async {
    final id = await _b.rpc('add_comment', params: {'post': post, 'body': body});
    return id.toString();
  }

  Future<void> deleteComment(String comment) =>
      _b.rpc('delete_comment', params: {'comment': comment});

  Future<void> reactPost(String post, String? emoji) =>
      _b.rpc('react_post', params: {'post': post, if (emoji != null) 'emoji': emoji});

  Future<String> createStory(
    String body,
    String background, {
    String? mediaPath,
  }) async {
    final id = await _b.rpc('create_story', params: {
      'body': body,
      'background': background,
      if (mediaPath != null) 'media': mediaPath,
    });
    return id.toString();
  }

  Future<void> deleteStory(String story) =>
      _b.rpc('delete_story', params: {'story': story});

  Future<void> viewStory(String story) =>
      _b.rpc('view_story', params: {'story': story});

  Future<List<Map<String, dynamic>>> storyViewers(String story) async {
    final res = await _b.rpc('story_viewers', params: {'story': story});
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> reportContent(
    String kind,
    String item,
    String category,
    String details,
  ) =>
      _b.rpc('report_content', params: {
        'kind': kind,
        'item': item,
        'category': category,
        'details': details,
      });

  /// Uploads a community photo: bucket community-media/<author_id>/<file>.
  Future<String> uploadPhoto(String authorId, Uint8List bytes,
      {required String ext, required String contentType}) async {
    final path = '$authorId/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _b.uploadBinary('community-media', path, bytes,
        contentType: contentType);
    return path;
  }

  Future<String?> communityMediaUrl(String? path) =>
      _cache.url('community-media', path, ttl: SignedUrlCache.mediaTtl);
}
