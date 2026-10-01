import 'jsonx.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    this.type,
    required this.title,
    this.body,
    this.link,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String? type;
  final String title;
  final String? body;
  final String? link;
  final String createdAt;
  final String? readAt;

  bool get unread => readAt == null;

  static AppNotification fromJson(Map<String, dynamic> m) => AppNotification(
        id: str(m, 'id') ?? '',
        type: str(m, 'type'),
        title: str(m, 'title') ?? 'Notification',
        body: str(m, 'body'),
        link: str(m, 'link'),
        createdAt: str(m, 'created_at') ?? DateTime.now().toIso8601String(),
        readAt: str(m, 'read_at'),
      );
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.tone = 'notice',
    this.linkUrl,
    this.linkLabel,
  });

  final String id;
  final String title;
  final String body;

  /// celebration | notice | urgent
  final String tone;
  final String? linkUrl;
  final String? linkLabel;

  String get headerLabel {
    switch (tone) {
      case 'celebration':
        return 'With love';
      case 'urgent':
        return 'Important';
      default:
        return 'Announcement';
    }
  }

  static Announcement fromJson(Map<String, dynamic> m) => Announcement(
        id: str(m, 'id') ?? '',
        title: str(m, 'title') ?? '',
        body: str(m, 'body') ?? '',
        tone: str(m, 'tone') ?? 'notice',
        linkUrl: str(m, 'link_url'),
        linkLabel: str(m, 'link_label'),
      );
}

class LiveNowItem {
  const LiveNowItem({
    required this.sessionId,
    required this.title,
    this.conferenceTitle,
    this.conferenceId,
    this.registered = false,
  });

  final String sessionId;
  final String title;
  final String? conferenceTitle;
  final String? conferenceId;
  final bool registered;

  static LiveNowItem fromJson(Map<String, dynamic> m) => LiveNowItem(
        sessionId: str(m, 'session_id') ?? str(m, 'id') ?? '',
        title: str(m, 'title') ?? 'Live session',
        conferenceTitle: str(m, 'conference_title') ?? str(m, 'conference'),
        conferenceId: str(m, 'conference_id'),
        registered: boolV(m, 'registered'),
      );
}
