import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/utils/completion.dart';
import 'package:isosha_esosheni/data/models/profile.dart';

OwnProfile _profile() => const OwnProfile(
      id: 'u',
      bioAbout:
          'A sufficiently long introduction that passes the forty chars rule.',
      bioValues: 'Faith',
      bioLookingFor: 'Marriage',
      bioFamilyGoals: 'A warm home',
      province: 'Gauteng',
      city: 'Johannesburg',
      languages: ['English'],
      profession: 'Teacher',
      education: 'Diploma',
      lifestyle: ['Calm'],
      interests: ['Reading'],
      personalityTraits: ['Patient'],
      relationshipIntentions: ['marriage'],
      numberOfChildren: 0,
      wantsChildren: 'yes',
    );

void main() {
  test('missing sections sorted by weight with exact labels', () {
    final missing = missingSections(_profile(), hasPreferences: false);
    final keys = missing.map((m) => m.key).toList();
    // avatar (10) first, then preferences (6)... video has weight 0 and is
    // only listed last.
    expect(keys.first, 'avatar');
    expect(missing.first.label, 'Profile photo');
    expect(keys, contains('preferences'));
    expect(missing.where((m) => m.key == 'preferences').first.label,
        'Partner preferences');
    expect(keys, contains('video'));
    expect(keys, isNot(contains('about')));
    // Sorted descending by weight.
    final weights = missing.map((m) => m.weight).toList();
    expect(weights, [...weights]..sort((a, b) => b.compareTo(a)));
  });

  test('about under 40 chars counts as missing', () {
    final p = _profile().copyWith(patch: {'bio_about': 'too short'});
    final missing = missingSections(p);
    expect(missing.any((m) => m.key == 'about'), isTrue);
    expect(
      missing.firstWhere((m) => m.key == 'about').label,
      'About me (at least 40 characters)',
    );
  });

  test('routes map to the right sections', () {
    final missing = missingSections(_profile());
    expect(missing.firstWhere((m) => m.key == 'avatar').route,
        '/profile/media');
    expect(missing.firstWhere((m) => m.key == 'preferences').route,
        '/profile/preferences');
  });
}
