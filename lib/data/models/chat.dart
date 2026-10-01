import 'jsonx.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.kind = 'text',
    this.body,
    this.mediaPath,
    this.mediaSeconds,
    required this.createdAt,
    this.deletedAt,
    this.reactions = const {},
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String kind; // text | image | voice | video | system
  final String? body;
  final String? mediaPath;
  final int? mediaSeconds;
  final String createdAt;
  final String? deletedAt;

  /// emoji -> list of user ids
  final Map<String, List<String>> reactions;

  bool get deleted => deletedAt != null;

  static ChatMessage fromJson(Map<String, dynamic> m) {
    final rawReactions = m['reactions'];
    final reactions = <String, List<String>>{};
    if (rawReactions is List) {
      for (final r in rawReactions.whereType<Map>()) {
        final emoji = str(Map<String, dynamic>.from(r), 'emoji');
        final userId = str(Map<String, dynamic>.from(r), 'user_id');
        if (emoji != null && userId != null) {
          reactions.putIfAbsent(emoji, () => []).add(userId);
        }
      }
    } else if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        reactions[k.toString()] =
            v is List ? v.map((e) => e.toString()).toList() : [v.toString()];
      });
    }
    return ChatMessage(
      id: str(m, 'id') ?? '',
      conversationId: str(m, 'conversation_id') ?? '',
      senderId: str(m, 'sender_id'),
      kind: str(m, 'kind') ?? 'text',
      body: str(m, 'body'),
      mediaPath: str(m, 'media_path'),
      mediaSeconds: intV(m, 'media_seconds'),
      createdAt: str(m, 'created_at') ?? DateTime.now().toIso8601String(),
      deletedAt: str(m, 'deleted_at'),
      reactions: reactions,
    );
  }

  ChatMessage copyWith({
    String? deletedAt,
    Map<String, List<String>>? reactions,
  }) =>
      ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        kind: kind,
        body: body,
        mediaPath: mediaPath,
        mediaSeconds: mediaSeconds,
        createdAt: createdAt,
        deletedAt: deletedAt ?? this.deletedAt,
        reactions: reactions ?? this.reactions,
      );
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.otherName,
    this.otherId,
    this.otherAvatarPath,
    this.lastKind = 'text',
    this.lastBody,
    this.lastSenderId,
    this.lastAt,
    this.unread = 0,
    this.closed = false,
  });

  final String id;
  final String otherName;
  final String? otherId;
  final String? otherAvatarPath;
  final String lastKind;
  final String? lastBody;
  final String? lastSenderId;
  final String? lastAt;
  final int unread;
  final bool closed;

  static ConversationSummary fromJson(Map<String, dynamic> m) =>
      ConversationSummary(
        id: str(m, 'id') ?? '',
        otherName: str(m, 'other_name') ?? str(m, 'name') ?? 'Member',
        otherId: str(m, 'other_id'),
        otherAvatarPath: str(m, 'other_avatar_path'),
        lastKind: str(m, 'last_kind') ?? 'text',
        lastBody: str(m, 'last_body'),
        lastSenderId: str(m, 'last_sender_id'),
        lastAt: str(m, 'last_at') ?? str(m, 'updated_at'),
        unread: intV(m, 'unread') ?? 0,
        closed: boolV(m, 'closed'),
      );
}

class ConversationInfo {
  const ConversationInfo({
    required this.id,
    this.closed = false,
    this.otherId,
    this.otherName,
    this.otherAvatarPath,
    this.otherReadAt,
    this.reactions = const [
      '❤️',
      '🙏',
      '😊',
      '😂',
      '👍',
      '🌿',
    ],
    this.videoEnabled = false,
    this.maxVoiceSeconds = 120,
    this.maxVideoSeconds = 60,
    this.relationship,
  });

  final String id;
  final bool closed;
  final String? otherId;
  final String? otherName;
  final String? otherAvatarPath;
  final String? otherReadAt;
  final List<String> reactions;
  final bool videoEnabled;
  final int maxVoiceSeconds;
  final int maxVideoSeconds;

  /// Raw relationship payload (see RelationshipState).
  final Map<String, dynamic>? relationship;

  static ConversationInfo fromJson(Map<String, dynamic> m) {
    final other = mapV(m, 'other') ?? m;
    return ConversationInfo(
      id: str(m, 'id') ?? str(m, 'conversation_id') ?? '',
      closed: boolV(m, 'closed'),
      otherId: str(other, 'id') ?? str(m, 'other_id'),
      otherName: str(other, 'display_name') ?? str(m, 'other_name'),
      otherAvatarPath: str(other, 'avatar_path') ?? str(m, 'other_avatar_path'),
      otherReadAt: str(other, 'last_read_at') ?? str(m, 'other_read_at'),
      reactions: (m['reactions'] as List?)?.whereType<String>().toList() ??
          const ['❤️', '🙏', '😊', '😂', '👍', ''],
      videoEnabled: boolV(m, 'video_enabled'),
      maxVoiceSeconds: intV(m, 'max_voice_seconds') ?? 120,
      maxVideoSeconds: intV(m, 'max_video_seconds') ?? 60,
      relationship: mapV(m, 'relationship'),
    );
  }

  ConversationInfo copyWith({String? otherReadAt}) => ConversationInfo(
        id: id,
        closed: closed,
        otherId: otherId,
        otherName: otherName,
        otherAvatarPath: otherAvatarPath,
        otherReadAt: otherReadAt ?? this.otherReadAt,
        reactions: reactions,
        videoEnabled: videoEnabled,
        maxVoiceSeconds: maxVoiceSeconds,
        maxVideoSeconds: maxVideoSeconds,
        relationship: relationship,
      );
}
