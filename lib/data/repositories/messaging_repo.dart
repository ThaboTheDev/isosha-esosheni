import 'dart:typed_data';

import '../../core/utils/signed_url_cache.dart';
import '../backend/backend.dart';
import '../models/chat.dart';
import '../models/misc.dart';

class ConversationBundle {
  const ConversationBundle({required this.info, required this.messages});
  final ConversationInfo info;
  final List<ChatMessage> messages;
}

class MessagingRepository {
  MessagingRepository(this._b, this._cache);

  final Backend _b;
  final SignedUrlCache _cache;

  Future<List<ConversationSummary>> conversations() async {
    final res = await _b.rpc('my_conversations');
    return (res as List? ?? [])
        .whereType<Map>()
        .map((e) => ConversationSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ConversationBundle> conversation(String conv) async {
    final info = Map<String, dynamic>.from(
        await _b.rpc('get_conversation', params: {'conv': conv}) as Map);
    final rows = await _b.select(
      'messages',
      equals: {'conversation_id': conv},
      limit: 50,
      orderBy: 'created_at',
      descending: true,
    );
    final messages = rows.map(ChatMessage.fromJson).toList();
    return ConversationBundle(
      info: ConversationInfo.fromJson(info),
      messages: messages,
    );
  }

  Future<List<ChatMessage>> earlierMessages(
      String conv, String before, int limit) async {
    final rows = await _b.select(
      'messages',
      equals: {'conversation_id': conv},
      lessThan: {'created_at': before},
      limit: limit,
      orderBy: 'created_at',
      descending: true,
    );
    return rows.map(ChatMessage.fromJson).toList();
  }

  Future<String> sendText(String conv, String body) async {
    final id = await _b.rpc('send_message', params: {
      'conv': conv,
      'kind': 'text',
      'body': body,
    });
    return id.toString();
  }

  Future<String> uploadAndSendMedia(
    String conv,
    String kind,
    Uint8List bytes, {
    required String ext,
    required String contentType,
    int? mediaSeconds,
  }) async {
    final path = '$conv/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await _b.uploadBinary(
      'chat-media',
      path,
      bytes,
      contentType: contentType,
      upsert: false,
    );
    final id = await _b.rpc('send_message', params: {
      'conv': conv,
      'kind': kind,
      'media_path': path,
      if (mediaSeconds != null) 'media_seconds': mediaSeconds,
    });
    return id.toString();
  }

  Future<void> markRead(String conv) =>
      _b.rpc('mark_conversation_read', params: {'conv': conv});

  Future<void> react(String msg, String emoji) =>
      _b.rpc('react_message', params: {'msg': msg, 'emoji': emoji});

  Future<void> deleteMessage(String msg) =>
      _b.rpc('delete_message', params: {'msg': msg});

  Future<String> chatMediaUrl(String? path) async =>
      (await _cache.url('chat-media', path, ttl: SignedUrlCache.chatMediaTtl)) ??
      '';

  CancelWatch watchMessages(
          String conv, void Function(ChatMessage) onMessage) =>
      _b.watch('messages', WatchEvent.insert, 'conversation_id=eq.$conv',
          (rec, _) => onMessage(ChatMessage.fromJson(rec)));

  CancelWatch watchReactions(
          String conv, void Function(Map<String, dynamic>) onReaction) =>
      _b.watch('message_reactions', WatchEvent.all, null, (rec, _) {
        if (rec['conversation_id'] == null ||
            rec['conversation_id'].toString() == conv) {
          onReaction(rec);
        }
      });

  CancelWatch watchReadReceipts(
          String conv, void Function(String userId, String at) onRead) =>
      _b.watch('conversation_participants', WatchEvent.update,
          'conversation_id=eq.$conv', (rec, _) {
        final at = rec['last_read_at']?.toString();
        final uid = rec['user_id']?.toString();
        if (at != null && uid != null) onRead(uid, at);
      });

  // Notifications
  Future<List<AppNotification>> notifications({int limit = 100}) async {
    final rows = await _b.select(
      'notifications',
      limit: limit,
      orderBy: 'created_at',
      descending: true,
    );
    return rows.map(AppNotification.fromJson).toList();
  }

  Future<void> markNotificationsRead({List<String>? ids}) =>
      _b.rpc('mark_notifications_read', params: {
        if (ids != null) 'ids': ids,
      });

  CancelWatch watchNotifications(
          String userId, void Function(AppNotification) onEvent) =>
      _b.watch('notifications', WatchEvent.insert, 'user_id=eq.$userId',
          (rec, _) => onEvent(AppNotification.fromJson(rec)));
}
