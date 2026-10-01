import '../../data/models/profile.dart';

/// The client only computes the "Still missing" list; the percentage
/// itself always comes from the database (`profiles.completion_percent`).
library;

class MissingSection {
  const MissingSection({
    required this.key,
    required this.label,
    required this.weight,
    required this.route,
  });

  final String key;
  final String label;
  final double weight;
  final String route;
}

const Map<String, double> defaultCompletionWeights = {
  'avatar': 10,
  'about': 10,
  'values': 8,
  'looking_for': 8,
  'family_goals': 7,
  'location': 6,
  'languages': 4,
  'career': 6,
  'education': 4,
  'lifestyle': 6,
  'interests': 6,
  'personality': 6,
  'intentions': 8,
  'children': 5,
  'preferences': 6,
  'video': 0,
};

const Map<String, String> missingLabels = {
  'avatar': 'Profile photo',
  'video': 'Introduction video',
  'about': 'About me (at least 40 characters)',
  'values': 'My values',
  'looking_for': 'What I am looking for',
  'family_goals': 'Family goals',
  'location': 'Province and city',
  'languages': 'Languages',
  'career': 'Profession or career',
  'education': 'Education',
  'lifestyle': 'Lifestyle',
  'interests': 'Interests or hobbies',
  'personality': 'Personality',
  'intentions': 'Relationship intention',
  'children': 'Children',
  'preferences': 'Partner preferences',
};

const Map<String, String> sectionRoutes = {
  'avatar': '/profile/media',
  'video': '/profile/media',
  'about': '/profile/edit',
  'values': '/profile/edit',
  'looking_for': '/profile/edit',
  'family_goals': '/profile/edit',
  'location': '/profile/edit',
  'languages': '/profile/edit',
  'career': '/profile/edit',
  'education': '/profile/edit',
  'lifestyle': '/profile/edit',
  'interests': '/profile/edit',
  'personality': '/profile/edit',
  'intentions': '/profile/edit',
  'children': '/profile/edit',
  'preferences': '/profile/preferences',
};

bool _filled(String key, OwnProfile p, {required bool hasPreferences}) {
  switch (key) {
    case 'avatar':
      return (p.avatarPath ?? '').isNotEmpty;
    case 'video':
      return (p.videoPath ?? '').isNotEmpty;
    case 'about':
      return (p.bioAbout ?? '').trim().length >= 40;
    case 'values':
      return (p.bioValues ?? '').trim().isNotEmpty || p.valuesTags.isNotEmpty;
    case 'looking_for':
      return (p.bioLookingFor ?? '').trim().isNotEmpty;
    case 'family_goals':
      return (p.bioFamilyGoals ?? '').trim().isNotEmpty;
    case 'location':
      return (p.province ?? '').isNotEmpty && (p.city ?? '').isNotEmpty;
    case 'languages':
      return p.languages.isNotEmpty;
    case 'career':
      return (p.profession ?? '').isNotEmpty || (p.career ?? '').isNotEmpty;
    case 'education':
      return (p.education ?? '').isNotEmpty;
    case 'lifestyle':
      return p.lifestyle.isNotEmpty;
    case 'interests':
      return p.interests.isNotEmpty || p.hobbies.isNotEmpty;
    case 'personality':
      return p.personalityTraits.isNotEmpty;
    case 'intentions':
      return p.relationshipIntentions.isNotEmpty;
    case 'children':
      return p.wantsChildren != null && p.numberOfChildren != null;
    case 'preferences':
      return hasPreferences;
    default:
      return true;
  }
}

/// Returns the missing sections sorted by weight (descending).
List<MissingSection> missingSections(
  OwnProfile p, {
  bool hasPreferences = false,
  Map<String, double>? weights,
}) {
  final w = weights ?? defaultCompletionWeights;
  final out = <MissingSection>[];
  w.forEach((key, weight) {
    if (!_filled(key, p, hasPreferences: hasPreferences)) {
      out.add(MissingSection(
        key: key,
        label: missingLabels[key] ?? key,
        weight: weight,
        route: sectionRoutes[key] ?? '/profile/edit',
      ));
    }
  });
  out.sort((a, b) => b.weight.compareTo(a.weight));
  return out;
}
