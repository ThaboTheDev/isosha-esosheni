import 'jsonx.dart';

class PostComment {
  const PostComment({
    required this.id,
    this.authorId,
    this.authorName,
    this.authorAvatarPath,
    this.body = '',
    required this.createdAt,
  });

  final String id;
  final String? authorId;
  final String? authorName;
  final String? authorAvatarPath;
  final String body;
  final String createdAt;

  static PostComment fromJson(Map<String, dynamic> m) => PostComment(
        id: str(m, 'id') ?? '',
        authorId: str(m, 'author_id') ?? str(m, 'user_id'),
        authorName: str(m, 'author_name') ?? str(m, 'display_name'),
        authorAvatarPath: str(m, 'author_avatar_path') ?? str(m, 'avatar_path'),
        body: str(m, 'body') ?? '',
        createdAt: str(m, 'created_at') ?? DateTime.now().toIso8601String(),
      );
}

class Post {
  const Post({
    required this.id,
    this.authorId,
    this.authorName,
    this.authorAvatarPath,
    this.body = '',
    this.mediaPath,
    required this.createdAt,
    this.editedAt,
    this.reactions = const {},
    this.reactionOptions = const ['❤️', '🙏', '😊', '👍', '🌿'],
    this.commentCount = 0,
    this.comments = const [],
    this.mine = false,
    this.hiddenReason,
  });

  final String id;
  final String? authorId;
  final String? authorName;
  final String? authorAvatarPath;
  final String body;
  final String? mediaPath;
  final String createdAt;
  final String? editedAt;

  /// emoji -> user ids
  final Map<String, List<String>> reactions;
  final List<String> reactionOptions;
  final int commentCount;
  final List<PostComment> comments;
  final bool mine;
  final String? hiddenReason;

  bool get hidden => hiddenReason != null;

  static Post fromJson(Map<String, dynamic> m) {
    final reactions = <String, List<String>>{};
    final raw = m['reactions'];
    if (raw is List) {
      for (final r in raw.whereType<Map>()) {
        final rm = Map<String, dynamic>.from(r);
        final emoji = str(rm, 'emoji');
        final uid = str(rm, 'user_id');
        if (emoji != null && uid != null) {
          reactions.putIfAbsent(emoji, () => []).add(uid);
        }
      }
    } else if (raw is Map) {
      raw.forEach((k, v) {
        reactions[k.toString()] =
            v is List ? v.map((e) => e.toString()).toList() : [];
      });
    }
    return Post(
      id: str(m, 'id') ?? '',
      authorId: str(m, 'author_id') ?? str(m, 'user_id'),
      authorName: str(m, 'author_name') ?? str(m, 'display_name'),
      authorAvatarPath: str(m, 'author_avatar_path') ?? str(m, 'avatar_path'),
      body: str(m, 'body') ?? '',
      mediaPath: str(m, 'media_path'),
      createdAt: str(m, 'created_at') ?? DateTime.now().toIso8601String(),
      editedAt: str(m, 'edited_at'),
      reactions: reactions,
      reactionOptions:
          (m['reaction_options'] as List?)?.whereType<String>().toList() ??
              const ['❤️', '🙏', '😊', '👍', '🌿'],
      commentCount: intV(m, 'comment_count') ?? intV(m, 'comments_count') ?? 0,
      comments: mapList(m['comments']).map(PostComment.fromJson).toList(),
      mine: boolV(m, 'mine') || boolV(m, 'is_mine'),
      hiddenReason: str(m, 'hidden_reason') ?? str(m, 'moderation_reason'),
    );
  }

  Post copyWith({
    Map<String, List<String>>? reactions,
    String? body,
    String? editedAt,
    List<PostComment>? comments,
    int? commentCount,
  }) =>
      Post(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorAvatarPath: authorAvatarPath,
        body: body ?? this.body,
        mediaPath: mediaPath,
        createdAt: createdAt,
        editedAt: editedAt ?? this.editedAt,
        reactions: reactions ?? this.reactions,
        reactionOptions: reactionOptions,
        commentCount: commentCount ?? this.commentCount,
        comments: comments ?? this.comments,
        mine: mine,
        hiddenReason: hiddenReason,
      );
}

class Story {
  const Story({
    required this.id,
    this.authorId,
    this.authorName,
    this.authorAvatarPath,
    this.body,
    this.background = 'night',
    this.mediaPath,
    required this.createdAt,
    this.mine = false,
    this.viewers = 0,
    this.seen = false,
  });

  final String id;
  final String? authorId;
  final String? authorName;
  final String? authorAvatarPath;
  final String? body;

  /// Backend key, sent unchanged: royal | crimson | gold | night.
  final String background;
  final String? mediaPath;
  final String createdAt;
  final bool mine;
  final int viewers;
  final bool seen;

  static Story fromJson(Map<String, dynamic> m) => Story(
        id: str(m, 'id') ?? '',
        authorId: str(m, 'author_id') ?? str(m, 'user_id'),
        authorName: str(m, 'author_name') ?? str(m, 'display_name'),
        authorAvatarPath: str(m, 'author_avatar_path') ?? str(m, 'avatar_path'),
        body: str(m, 'body'),
        background: str(m, 'background') ?? 'night',
        mediaPath: str(m, 'media_path'),
        createdAt: str(m, 'created_at') ?? DateTime.now().toIso8601String(),
        mine: boolV(m, 'mine') || boolV(m, 'is_mine'),
        viewers: intV(m, 'viewers') ?? 0,
        seen: boolV(m, 'seen'),
      );
}

class StoryGroup {
  const StoryGroup({
    required this.authorId,
    this.authorName,
    this.authorAvatarPath,
    this.seen = false,
    this.mine = false,
    this.stories = const [],
  });

  final String authorId;
  final String? authorName;
  final String? authorAvatarPath;
  final bool seen;
  final bool mine;
  final List<Story> stories;

  static StoryGroup fromJson(Map<String, dynamic> m) => StoryGroup(
        authorId: str(m, 'author_id') ?? str(m, 'user_id') ?? '',
        authorName: str(m, 'author_name') ?? str(m, 'display_name'),
        authorAvatarPath: str(m, 'author_avatar_path') ?? str(m, 'avatar_path'),
        seen: boolV(m, 'seen'),
        mine: boolV(m, 'mine') || boolV(m, 'is_mine'),
        stories: mapList(m['stories']).map(Story.fromJson).toList(),
      );
}
