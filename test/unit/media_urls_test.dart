import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/utils/media_urls.dart';

void main() {
  test('youtube id extraction', () {
    expect(MediaUrls.extractYouTubeId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ');
    expect(
        MediaUrls.extractYouTubeId(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ');
    expect(
        MediaUrls.extractYouTubeId(
            'https://www.youtube.com/embed/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ');
    expect(
        MediaUrls.extractYouTubeId(
            'https://www.youtube.com/live/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ');
    expect(MediaUrls.extractYouTubeId('https://example.com'), isNull);
  });

  test('embed url', () {
    expect(
      MediaUrls.youTubeEmbedUrl('abc123'),
      'https://www.youtube-nocookie.com/embed/abc123'
      '?autoplay=1&rel=0&modestbranding=1',
    );
  });

  test('jitsi url builder', () {
    final url = MediaUrls.jitsiUrl('meet.trsh.org', 'room1', 'Naledi "Lee" D');
    expect(url, startsWith('https://meet.trsh.org/room1#'));
    expect(url, contains('userInfo.displayName="Naledi \'Lee\' D"'));
    expect(url, contains('config.prejoinPageEnabled=false'));
    expect(url, contains('config.disableDeepLinking=true'));
    expect(url, contains('config.subject="Isosha Esosheni"'));
  });
}
