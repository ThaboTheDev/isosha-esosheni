import 'jsonx.dart';

/// The signed-in member's own `profiles` row.
class OwnProfile {
  const OwnProfile({
    required this.id,
    this.fullName,
    this.preferredName,
    this.gender,
    this.dateOfBirth,
    this.email,
    this.avatarPath,
    this.videoPath,
    this.bioAbout,
    this.bioValues,
    this.valuesTags = const [],
    this.bioLookingFor,
    this.bioExpectations,
    this.relationshipIntentions = const [],
    this.maritalStatus,
    this.membershipNumber,
    this.membershipStatus,
    this.numberOfChildren,
    this.wantsChildren,
    this.bioFamilyGoals,
    this.longTermGoals,
    this.education,
    this.employmentStatus,
    this.profession,
    this.career,
    this.lifestyle = const [],
    this.bioLifestyle,
    this.interests = const [],
    this.hobbies = const [],
    this.likes = const [],
    this.dislikes = const [],
    this.personalityTraits = const [],
    this.communicationPreferences,
    this.spiritualInterests = const [],
    this.country,
    this.province,
    this.city,
    this.languages = const [],
    this.contactPhone,
    this.accountStatus = 'active',
    this.isDemo = false,
    this.completionPercent = 0,
    this.visibleToOthers = true,
  });

  final String id;
  final String? fullName;
  final String? preferredName;
  final String? gender;
  final String? dateOfBirth;
  final String? email;
  final String? avatarPath;
  final String? videoPath;
  final String? bioAbout;
  final String? bioValues;
  final List<String> valuesTags;
  final String? bioLookingFor;
  final String? bioExpectations;
  final List<String> relationshipIntentions;
  final String? maritalStatus;
  final String? membershipNumber;
  final String? membershipStatus;
  final int? numberOfChildren;
  final String? wantsChildren;
  final String? bioFamilyGoals;
  final String? longTermGoals;
  final String? education;
  final String? employmentStatus;
  final String? profession;
  final String? career;
  final List<String> lifestyle;
  final String? bioLifestyle;
  final List<String> interests;
  final List<String> hobbies;
  final List<String> likes;
  final List<String> dislikes;
  final List<String> personalityTraits;
  final String? communicationPreferences;
  final List<String> spiritualInterests;
  final String? country;
  final String? province;
  final String? city;
  final List<String> languages;
  final String? contactPhone;
  final String accountStatus;
  final bool isDemo;
  final int completionPercent;
  final bool visibleToOthers;

  String get firstName {
    final n = (preferredName?.isNotEmpty == true ? preferredName : fullName) ?? '';
    return n.trim().split(RegExp(r'\s+')).first;
  }

  static OwnProfile fromJson(Map<String, dynamic> m) => OwnProfile(
        id: str(m, 'id') ?? '',
        fullName: str(m, 'full_name'),
        preferredName: str(m, 'preferred_name'),
        gender: str(m, 'gender'),
        dateOfBirth: str(m, 'date_of_birth'),
        email: str(m, 'email'),
        avatarPath: str(m, 'avatar_path'),
        videoPath: str(m, 'video_path'),
        bioAbout: str(m, 'bio_about'),
        bioValues: str(m, 'bio_values'),
        valuesTags: strList(m, 'values_tags'),
        bioLookingFor: str(m, 'bio_looking_for'),
        bioExpectations: str(m, 'bio_expectations'),
        relationshipIntentions: strList(m, 'relationship_intentions'),
        maritalStatus: str(m, 'marital_status'),
        membershipNumber: str(m, 'membership_number'),
        membershipStatus: str(m, 'membership_status'),
        numberOfChildren: intV(m, 'number_of_children'),
        wantsChildren: str(m, 'wants_children'),
        bioFamilyGoals: str(m, 'bio_family_goals'),
        longTermGoals: str(m, 'long_term_goals'),
        education: str(m, 'education'),
        employmentStatus: str(m, 'employment_status'),
        profession: str(m, 'profession'),
        career: str(m, 'career'),
        lifestyle: strList(m, 'lifestyle'),
        bioLifestyle: str(m, 'bio_lifestyle'),
        interests: strList(m, 'interests'),
        hobbies: strList(m, 'hobbies'),
        likes: strList(m, 'likes'),
        dislikes: strList(m, 'dislikes'),
        personalityTraits: strList(m, 'personality_traits'),
        communicationPreferences: str(m, 'communication_preferences'),
        spiritualInterests: strList(m, 'spiritual_interests'),
        country: str(m, 'country'),
        province: str(m, 'province'),
        city: str(m, 'city'),
        languages: strList(m, 'languages'),
        contactPhone: str(m, 'contact_phone'),
        accountStatus: str(m, 'account_status') ?? 'active',
        isDemo: boolV(m, 'is_demo'),
        completionPercent: intV(m, 'completion_percent') ?? 0,
        visibleToOthers: boolV(m, 'visible_to_others', true),
      );

  OwnProfile copyWith({Map<String, dynamic>? patch}) {
    if (patch == null) return this;
    final m = <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'preferred_name': preferredName,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'email': email,
      'avatar_path': avatarPath,
      'video_path': videoPath,
      'bio_about': bioAbout,
      'bio_values': bioValues,
      'values_tags': valuesTags,
      'bio_looking_for': bioLookingFor,
      'bio_expectations': bioExpectations,
      'relationship_intentions': relationshipIntentions,
      'marital_status': maritalStatus,
      'membership_number': membershipNumber,
      'membership_status': membershipStatus,
      'number_of_children': numberOfChildren,
      'wants_children': wantsChildren,
      'bio_family_goals': bioFamilyGoals,
      'long_term_goals': longTermGoals,
      'education': education,
      'employment_status': employmentStatus,
      'profession': profession,
      'career': career,
      'lifestyle': lifestyle,
      'bio_lifestyle': bioLifestyle,
      'interests': interests,
      'hobbies': hobbies,
      'likes': likes,
      'dislikes': dislikes,
      'personality_traits': personalityTraits,
      'communication_preferences': communicationPreferences,
      'spiritual_interests': spiritualInterests,
      'country': country,
      'province': province,
      'city': city,
      'languages': languages,
      'contact_phone': contactPhone,
      'account_status': accountStatus,
      'is_demo': isDemo,
      'completion_percent': completionPercent,
      'visible_to_others': visibleToOthers,
    };
    patch.forEach((k, v) => m[k] = v);
    return OwnProfile.fromJson(m);
  }
}

class PartnerPreferences {
  const PartnerPreferences({
    this.minAge = 18,
    this.maxAge = 99,
    this.preferredGender = 'any',
    this.preferredProvinces = const [],
    this.preferredLanguages = const [],
    this.preferredIntentions = const [],
    this.openToPolygamy = false,
    this.dealbreakers = const [],
    this.notes,
  });

  final int minAge;
  final int maxAge;
  final String preferredGender;
  final List<String> preferredProvinces;
  final List<String> preferredLanguages;
  final List<String> preferredIntentions;
  final bool openToPolygamy;
  final List<String> dealbreakers;
  final String? notes;

  static PartnerPreferences? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return PartnerPreferences(
      minAge: intV(m, 'min_age') ?? 18,
      maxAge: intV(m, 'max_age') ?? 99,
      preferredGender: str(m, 'preferred_gender') ?? 'any',
      preferredProvinces: strList(m, 'preferred_provinces'),
      preferredLanguages: strList(m, 'preferred_languages'),
      preferredIntentions: strList(m, 'preferred_intentions'),
      openToPolygamy: boolV(m, 'open_to_polygamy'),
      dealbreakers: strList(m, 'dealbreakers'),
      notes: str(m, 'notes'),
    );
  }

  Map<String, dynamic> toJson() => {
        'min_age': minAge,
        'max_age': maxAge,
        'preferred_gender': preferredGender,
        'preferred_provinces': preferredProvinces,
        'preferred_languages': preferredLanguages,
        'preferred_intentions': preferredIntentions,
        'open_to_polygamy': openToPolygamy,
        'dealbreakers': dealbreakers,
        'notes': notes,
      };
}

class FieldVisibility {
  const FieldVisibility({required this.key, required this.label, this.visibility = 'all', this.locked = false});
  final String key;
  final String label;
  final String visibility; // all | matches | me
  final bool locked;

  FieldVisibility copyWith({String? visibility}) => FieldVisibility(
        key: key,
        label: label,
        visibility: visibility ?? this.visibility,
        locked: locked,
      );
}

/// Field keys, labels and lock rules for the privacy screen.
const List<FieldVisibility> privacyFields = [
  FieldVisibility(key: 'avatar', label: 'Profile photo'),
  FieldVisibility(key: 'full_name', label: 'Full name'),
  FieldVisibility(key: 'age', label: 'Age'),
  FieldVisibility(key: 'location', label: 'Province and city'),
  FieldVisibility(key: 'languages', label: 'Languages'),
  FieldVisibility(key: 'career', label: 'Profession and career'),
  FieldVisibility(key: 'education', label: 'Education'),
  FieldVisibility(key: 'biography', label: 'About me and what I seek'),
  FieldVisibility(key: 'family', label: 'Family goals'),
  FieldVisibility(key: 'children', label: 'Children'),
  FieldVisibility(
    key: 'marital_status',
    label: 'Marital status',
    locked: true,
  ),
  FieldVisibility(key: 'lifestyle', label: 'Lifestyle'),
  FieldVisibility(key: 'interests', label: 'Interests and hobbies'),
  FieldVisibility(key: 'personality', label: 'Personality'),
  FieldVisibility(key: 'spiritual', label: 'Spiritual interests'),
  FieldVisibility(key: 'video', label: 'Introduction video'),
  FieldVisibility(key: 'contact', label: 'Contact details'),
];
