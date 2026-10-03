import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../discover/discover_screen.dart' show provinces, saLanguages;

const Map<String, String> intentionOptions = {
  'friendship': 'Friendship',
  'serious_relationship': 'Serious relationship',
  'courtship': 'Courtship',
  'marriage': 'Marriage',
  'future_marriage': 'Marriage in future',
  'traditional_family': 'Traditional family relationship',
  'monogamous_marriage': 'Monogamous marriage',
  'open_to_polygamous_marriage': 'Open to polygamous marriage',
};

const List<String> selfMaritalStatuses = ['single', 'separated', 'divorced', 'widowed'];
const Map<String, String> maritalLabelsEn = {
  'single': 'Single',
  'separated': 'Separated',
  'divorced': 'Divorced',
  'widowed': 'Widowed',
};
const List<String> wantsChildrenOptions = ['yes', 'no', 'open', 'unsure'];
const Map<String, String> wantsChildrenLabels = {
  'yes': 'Yes, I want children',
  'no': 'No',
  'open': 'Open to it',
  'unsure': 'Not sure yet',
};
const List<String> educationOptions = [
  'Primary school',
  'High school / Matric',
  'Certificate',
  'Diploma',
  "Bachelor's degree",
  'Honours',
  "Master's degree",
  'Doctorate',
  'Trade qualification',
];
const List<String> employmentOptions = [
  'Employed',
  'Self-employed',
  'Business owner',
  'Studying',
  'Seeking work',
  'Retired',
];

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final Map<String, TextEditingController> _c = {};
  bool _busy = false;
  String? _error;
  final Map<String, String?> _errors = {};

  List<String> _intentions = [];
  String? _marital;
  String? _wantsChildren;
  int _children = 0;
  List<String> _valuesTags = [];
  List<String> _lifestyle = [];
  List<String> _interests = [];
  List<String> _hobbies = [];
  List<String> _likes = [];
  List<String> _dislikes = [];
  List<String> _personality = [];
  List<String> _spiritual = [];
  List<String> _languages = [];

  @override
  void initState() {
    super.initState();
    final me = context.read(sessionProvider).me;
    if (me != null) {
      _c['preferred_name'] = TextEditingController(text: me.preferredName);
      _c['bio_about'] = TextEditingController(text: me.bioAbout);
      _c['bio_values'] = TextEditingController(text: me.bioValues);
      _c['bio_looking_for'] = TextEditingController(text: me.bioLookingFor);
      _c['bio_expectations'] = TextEditingController(text: me.bioExpectations);
      _c['bio_family_goals'] = TextEditingController(text: me.bioFamilyGoals);
      _c['long_term_goals'] = TextEditingController(text: me.longTermGoals);
      _c['profession'] = TextEditingController(text: me.profession);
      _c['career'] = TextEditingController(text: me.career);
      _c['bio_lifestyle'] = TextEditingController(text: me.bioLifestyle);
      _c['country'] = TextEditingController(text: me.country ?? 'South Africa');
      _c['city'] = TextEditingController(text: me.city);
      _c['contact_phone'] = TextEditingController(text: me.contactPhone);
      _c['membership_number'] = TextEditingController(text: me.membershipNumber);
      _c['education'] = TextEditingController(text: me.education);
      _c['employment'] = TextEditingController(text: me.employmentStatus);
      _c['province'] = TextEditingController(text: me.province);
      _intentions = List.of(me.relationshipIntentions);
      _marital = selfMaritalStatuses.contains(me.maritalStatus)
          ? me.maritalStatus
          : null;
      _wantsChildren = me.wantsChildren;
      _children = me.numberOfChildren ?? 0;
      _valuesTags = List.of(me.valuesTags);
      _lifestyle = List.of(me.lifestyle);
      _interests = List.of(me.interests);
      _hobbies = List.of(me.hobbies);
      _likes = List.of(me.likes);
      _dislikes = List.of(me.dislikes);
      _personality = List.of(me.personalityTraits);
      _spiritual = List.of(me.spiritualInterests);
      _languages = List.of(me.languages);
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final errs = <String, String?>{};
    final phone = _c['contact_phone']!.text.trim();
    errs['phone'] = Validators.phone(phone);
    final memberNo = _c['membership_number']!.text.trim();
    errs['member'] = Validators.membershipNumber(memberNo);
    if ((_c['bio_about']?.text.length ?? 0) > 2000) {
      errs['about'] = 'About me is limited to 2000 characters.';
    }
    setState(() => _errors.addAll(errs));
    if (errs.values.any((v) => v != null)) return;

    String? blank(String k) {
      final v = _c[k]!.text.trim();
      return v.isEmpty ? null : v;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final me = context.read(sessionProvider).me!;
      final updated = await context.read(accountRepoProvider).updateProfile(
            me.id,
            {
              'preferred_name': blank('preferred_name'),
              'bio_about': blank('bio_about'),
              'bio_values': blank('bio_values'),
              'values_tags': _valuesTags,
              'bio_looking_for': blank('bio_looking_for'),
              'bio_expectations': blank('bio_expectations'),
              'relationship_intentions': _intentions,
              if (_marital != null) 'marital_status': _marital,
              'membership_number': blank('membership_number'),
              'number_of_children': _children,
              'wants_children': _wantsChildren,
              'bio_family_goals': blank('bio_family_goals'),
              'long_term_goals': blank('long_term_goals'),
              'education': blank('education') ?? me.education,
              'employment_status': blank('employment') ?? me.employmentStatus,
              'profession': blank('profession'),
              'career': blank('career'),
              'lifestyle': _lifestyle,
              'bio_lifestyle': blank('bio_lifestyle'),
              'interests': _interests,
              'hobbies': _hobbies,
              'likes': _likes,
              'dislikes': _dislikes,
              'personality_traits': _personality,
              'spiritual_interests': _spiritual,
              'country': blank('country'),
              'province': blank('province') ?? me.province,
              'city': blank('city'),
              'languages': _languages,
              'contact_phone': blank('contact_phone'),
            },
          );
      context.read(sessionProvider.notifier).patchMe(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved.'), backgroundColor: C.sage));
      }
    } catch (e) {
      if (mounted) {
        final msg = friendlyError(e);
        setState(() => _error = msg.contains('membership')
            ? 'This membership number is already linked to another account.'
            : msg);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _multi(String label, List<String> values, Map<String, String> options,
      ValueChanged<List<String>> onSet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: T.bodyStrong.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final e in options.entries)
              FilterChip(
                label: Text(e.value, style: const TextStyle(fontSize: 12.5)),
                selected: values.contains(e.key),
                onSelected: (sel) {
                  final next = List.of(values);
                  if (sel) {
                    next.add(e.key);
                  } else {
                    next.remove(e.key);
                  }
                  onSet(next);
                },
                selectedColor: C.plum100,
                checkmarkColor: C.plum700,
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider).me;
    final workflowMarital = me?.maritalStatus != null &&
        !selfMaritalStatuses.contains(me!.maritalStatus);
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Profile details'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('About me'),
          AppField(
            label: 'Preferred name',
            child: TextField(controller: _c['preferred_name'],
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'About me',
            error: _errors['about'],
            child: TextField(controller: _c['bio_about'],
                maxLines: 4, maxLength: 2000,
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'My values',
            child: TextField(controller: _c['bio_values'],
                maxLines: 2, maxLength: 1500,
                decoration: const InputDecoration(filled: true)),
          ),
          TagInput(tags: _valuesTags, onChanged: (v) => setState(() => _valuesTags = v)),
          const SizedBox(height: 10),
          AppField(
            label: 'What I am looking for',
            child: TextField(controller: _c['bio_looking_for'],
                maxLines: 3,
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'My expectations',
            child: TextField(controller: _c['bio_expectations'],
                maxLines: 2,
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 16),
          _section('Relationship'),
          _multi('Relationship intentions', _intentions, intentionOptions,
              (v) => setState(() => _intentions = v)),
          if (workflowMarital)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Relationship status: ${me.maritalStatus}. This is set by '
                'the relationship workflow.',
                style: T.small.copyWith(fontSize: 12.5),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _marital,
              items: [
                const DropdownMenuItem(value: null, child: Text('Select')),
                for (final s in selfMaritalStatuses)
                  DropdownMenuItem(
                      value: s, child: Text(maritalLabelsEn[s] ?? s)),
              ],
              onChanged: (v) => setState(() => _marital = v),
              decoration:
                  const InputDecoration(labelText: 'Marital status', filled: true),
            ),
          const SizedBox(height: 10),
          AppField(
            label: 'Membership number (optional)',
            error: _errors['member'],
            child: TextField(controller: _c['membership_number'],
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 16),
          _section('Family'),
          Row(
            children: [
              Text('Children: $_children', style: T.bodyStrong.copyWith(fontSize: 14)),
              IconButton(
                  onPressed: _children > 0
                      ? () => setState(() => _children--)
                      : null,
                  icon: const Icon(Icons.remove)),
              IconButton(
                  onPressed: _children < 30
                      ? () => setState(() => _children++)
                      : null,
                  icon: const Icon(Icons.add)),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _wantsChildren,
            items: [
              const DropdownMenuItem(value: null, child: Text('Select')),
              for (final w in wantsChildrenOptions)
                DropdownMenuItem(
                    value: w, child: Text(wantsChildrenLabels[w] ?? w)),
            ],
            onChanged: (v) => setState(() => _wantsChildren = v),
            decoration:
                const InputDecoration(labelText: 'Wants children', filled: true),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'Family goals',
            child: TextField(controller: _c['bio_family_goals'],
                maxLines: 2,
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'Long-term goals',
            child: TextField(controller: _c['long_term_goals'],
                maxLines: 2,
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 16),
          _section('Education and work'),
          DropdownButtonFormField<String>(
            initialValue: me?.education,
            items: [
              const DropdownMenuItem(value: null, child: Text('Select')),
              for (final e in educationOptions)
                DropdownMenuItem(value: e, child: Text(e)),
            ],
            onChanged: (v) => _c['education']!.text = v ?? '',
            decoration: const InputDecoration(labelText: 'Education', filled: true),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: me?.employmentStatus,
            items: [
              const DropdownMenuItem(value: null, child: Text('Select')),
              for (final e in employmentOptions)
                DropdownMenuItem(value: e, child: Text(e)),
            ],
            onChanged: (v) => _c['employment']!.text = v ?? '',
            decoration:
                const InputDecoration(labelText: 'Employment status', filled: true),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'Profession',
            child: TextField(controller: _c['profession'],
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'Career',
            child: TextField(controller: _c['career'],
                maxLines: 2,
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 16),
          _section('Character and lifestyle'),
          AppField(
            label: 'Lifestyle tags',
            child: TagInput(tags: _lifestyle, onChanged: (v) => setState(() => _lifestyle = v)),
          ),
          AppField(
            label: 'About my lifestyle',
            child: TextField(controller: _c['bio_lifestyle'],
                maxLines: 2,
                decoration: const InputDecoration(filled: true)),
          ),
          AppField(
            label: 'Interests',
            child: TagInput(tags: _interests, onChanged: (v) => setState(() => _interests = v)),
          ),
          AppField(
            label: 'Hobbies',
            child: TagInput(tags: _hobbies, onChanged: (v) => setState(() => _hobbies = v)),
          ),
          AppField(
            label: 'Likes',
            child: TagInput(tags: _likes, onChanged: (v) => setState(() => _likes = v)),
          ),
          AppField(
            label: 'Dislikes',
            child: TagInput(tags: _dislikes, onChanged: (v) => setState(() => _dislikes = v)),
          ),
          AppField(
            label: 'Personality',
            child: TagInput(
                tags: _personality,
                onChanged: (v) => setState(() => _personality = v)),
          ),
          AppField(
            label: 'Spiritual interests',
            child: TagInput(tags: _spiritual, onChanged: (v) => setState(() => _spiritual = v)),
          ),
          const SizedBox(height: 16),
          _section('Location and language'),
          AppField(
            label: 'Country',
            child: TextField(controller: _c['country'],
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: me?.province,
            items: [
              const DropdownMenuItem(value: null, child: Text('Select')),
              for (final p in provinces)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) => _c['province']!.text = v ?? '',
            decoration: const InputDecoration(labelText: 'Province', filled: true),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'City',
            child: TextField(controller: _c['city'],
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 10),
          AppField(
            label: 'Languages',
            child: _multiInline(_languages, saLanguages,
                (v) => setState(() => _languages = v)),
          ),
          AppField(
            label: 'Contact phone (kept private)',
            error: _errors['phone'],
            child: TextField(controller: _c['contact_phone'],
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(filled: true)),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(_error!,
                  style: const TextStyle(color: C.rust, fontSize: 13)),
            ),
          PrimaryButton(
            label: 'Save profile',
            busy: _busy,
            onPressed: _save,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _multiInline(
      List<String> values, List<String> options, ValueChanged<List<String>> onSet) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final o in options)
          FilterChip(
            label: Text(o, style: const TextStyle(fontSize: 12.5)),
            selected: values.contains(o),
            onSelected: (sel) {
              final next = List.of(values);
              if (sel) {
                next.add(o);
              } else {
                next.remove(o);
              }
              onSet(next);
            },
            selectedColor: C.plum100,
            checkmarkColor: C.plum700,
          ),
      ],
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: T.headline.copyWith(fontSize: 22)),
      );
}
