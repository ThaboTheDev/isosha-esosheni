/// Helpers for live-session embeds (YouTube / Jitsi).
library;

class MediaUrls {
  MediaUrls._();

  static final _ytPatterns = [
    RegExp(r'youtu\.be/([A-Za-z0-9_-]{6,})'),
    RegExp(r'youtube\.com/watch\?v=([A-Za-z0-9_-]{6,})'),
    RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{6,})'),
    RegExp(r'youtube\.com/live/([A-Za-z0-9_-]{6,})'),
    RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{6,})'),
  ];

  /// Extracts a YouTube video id from watch/live/embed/shortened URLs.
  static String? extractYouTubeId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    for (final re in _ytPatterns) {
      final m = re.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  static String youTubeEmbedUrl(String videoId) =>
      'https://www.youtube-nocookie.com/embed/$videoId'
      '?autoplay=1&rel=0&modestbranding=1';

  /// Jitsi meet URL with the display name and config flags the web uses.
  static String jitsiUrl(String domain, String room, String displayName) {
    final name = displayName.replaceAll('"', "'");
    return 'https://$domain/$room#userInfo.displayName="$name"'
        '&config.prejoinPageEnabled=false'
        '&config.disableDeepLinking=true'
        '&config.subject="Isosha Esosheni"';
  }
}
