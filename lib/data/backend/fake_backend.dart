import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'backend.dart';

/// In-memory demo backend. Lets the whole UI be developed and demoed
/// without credentials. All business "rules" here only shape demo data;
/// the server remains the authority when Supabase is configured.
class FakeBackend implements Backend {
  FakeBackend() {
    _seed();
  }

  static const String me = 'u-me';

  String? _userId = me;

  final Map<String, dynamic> _profiles = {};
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _posts = [];
  final List<Map<String, dynamic>> _comments = [];
  final List<Map<String, dynamic>> _notifications = [];
  final List<Map<String, dynamic>> _stories = [];
  final List<Map<String, dynamic>> _liveChat = [];
  final Map<String, Map<String, dynamic>> _settings = {};
  final Map<String, String> _storage = {};
  final Map<String, dynamic> _partnerPrefs = {};
  final Map<String, Map<String, dynamic>> _visibility = {};

  final List<_FakeSub> _subs = [];

  final Random _rnd = Random(7);

  String _uuid() =>
      'f${(_rnd.nextDouble() * 1e15).round().toRadixString(16).padLeft(12, '0')}';

  String _now() => DateTime.now().toUtc().toIso8601String();

  String _ago(Duration d) =>
      DateTime.now().toUtc().subtract(d).toIso8601String();

  // ------------------------------------------------------------------
  void _seed() {
    _profiles[me] = {
      'id': me,
      'full_name': 'Naledi Dlamini',
      'preferred_name': 'Naledi',
      'gender': 'female',
      'date_of_birth': '1994-05-12',
      'email': 'naledi@demo.isosha.invalid',
      'avatar_path': null,
      'video_path': null,
      'bio_about':
          'I am a teacher who loves reading, community and quiet Sundays. '
          'Faith shapes my days and I am looking for a relationship that '
          'grows with intention and respect.',
      'bio_values': 'Family, honesty, prayer and service.',
      'values_tags': ['Faith', 'Family', 'Honesty'],
      'bio_looking_for': 'A serious relationship that moves toward marriage.',
      'bio_expectations': 'Open communication and patience.',
      'relationship_intentions': ['serious_relationship', 'marriage'],
      'marital_status': 'single',
      'membership_number': null,
      'membership_status': null,
      'number_of_children': 0,
      'wants_children': 'yes',
      'bio_family_goals': 'A home built on faith and warmth.',
      'long_term_goals': 'Teaching, family, community work.',
      'education': "Bachelor's degree",
      'employment_status': 'Employed',
      'profession': 'Teacher',
      'career': 'Primary school educator',
      'lifestyle': ['Early riser', 'Home cooking'],
      'bio_lifestyle': 'Simple and steady.',
      'interests': ['Reading', 'Choir'],
      'hobbies': ['Gardening'],
      'likes': ['Quiet mornings'],
      'dislikes': ['Rudeness'],
      'personality_traits': ['Patient', 'Warm'],
      'communication_preferences': 'Calls in the evening.',
      'spiritual_interests': ['Bible study'],
      'country': 'South Africa',
      'province': 'Gauteng',
      'city': 'Johannesburg',
      'languages': ['English', 'isiZulu'],
      'contact_phone': null,
      'account_status': 'active',
      'is_demo': true,
      'completion_percent': 82,
      'visible_to_others': true,
    };

    _messages.addAll([
      _msg('msg-1', 'c-1', 'u-1', 'text',
          'Good day Naledi, thank you for accepting. How has your week been?'),
      _msg('msg-2', 'c-1', me, 'text',
          'It has been blessed, thank you. And yours?'),
      _msg('msg-3', 'c-1', 'u-1', 'text',
          'Busy but good. I attended the last Love Life Conference talk and '
          'it stayed with me.'),
      _msg('msg-4', 'c-1', me, 'text', 'Which session was it?'),
      _msg('msg-5', 'c-1', 'u-1', 'system',
          'You are both in the Talking Stage. Take your time; Indawo '
          'Ephakeme guidance comes before dating.'),
    ]);

    _posts.addAll([
      {
        'id': 'p-1',
        'author_id': 'u-2',
        'author_name': 'Zanele Mbeki',
        'author_avatar_path': null,
        'body': 'Gratitude turns what we have into enough. Wishing everyone '
            'a blessed week ahead.',
        'media_path': null,
        'created_at': _ago(const Duration(hours: 3)),
        'edited_at': null,
        'reaction_options': ['❤️', '🙏', '😊', '👍', '🌿'],
        'comment_count': 1,
        'mine': false,
        'hidden_reason': null,
      },
      {
        'id': 'p-2',
        'author_id': me,
        'author_name': 'Naledi Dlamini',
        'body': 'Finished a wonderful book on families that pray together. '
            'Happy to lend it to anyone.',
        'created_at': _ago(const Duration(hours: 26)),
        'comment_count': 0,
        'mine': true,
      },
    ]);
    _comments.add({
      'id': 'cm-1',
      'post_id': 'p-1',
      'author_id': 'u-4',
      'author_name': 'Lerato Khumalo',
      'body': 'Amen, thank you for this.',
      'created_at': _ago(const Duration(hours: 2)),
    });

    _stories.addAll([
      {
        'id': 's-1',
        'author_id': 'u-2',
        'author_name': 'Zanele Mbeki',
        'body': 'Morning walk, grateful heart.',
        'background': 'royal',
        'media_path': null,
        'created_at': _ago(const Duration(hours: 1)),
        'seen': false,
        'viewers': 4,
      },
      {
        'id': 's-2',
        'author_id': me,
        'author_name': 'Naledi Dlamini',
        'body': 'Weekend blessing to all.',
        'background': 'crimson',
        'created_at': _ago(const Duration(hours: 5)),
        'seen': true,
        'viewers': 2,
      },
    ]);

    _notifications.addAll([
      {
        'id': 'n-1',
        'type': 'interest_received',
        'title': 'New interest',
        'body': 'Zanele Mbeki has shown interest in you.',
        'link': '/connections?tab=received',
        'created_at': _ago(const Duration(hours: 4)),
        'read_at': null,
      },
      {
        'id': 'n-2',
        'type': 'message',
        'title': 'New message',
        'body': 'Thabo Nkosi sent you a message.',
        'link': '/messages/c-1',
        'created_at': _ago(const Duration(minutes: 40)),
        'read_at': null,
      },
    ]);

    _settings['profile.completion_weights'] = {
      'value': {
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
      },
    };
    _settings['profile.min_completion_for_discovery'] = {'value': 60};
    _settings['matching.disclaimer'] = {
      'value':
          'Scores are a starting point for conversation, not a verdict. '
          'They reflect only what members have chosen to share.',
    };
  }

  Map<String, dynamic> _msg(String id, String conv, String? sender,
      String kind, String? body) {
    return {
      'id': id,
      'conversation_id': conv,
      'sender_id': sender,
      'kind': kind,
      'body': body,
      'media_path': null,
      'media_seconds': null,
      'created_at': _now(),
      'deleted_at': null,
    };
  }

  Map<String, dynamic> _card(String id, String name, int age, String city,
          String province, String profession,
          {int? score,
          List<String> reasons = const [],
          String? status,
          Map<String, dynamic>? household,
          String? interestReceived,
          bool matched = false,
          bool interestSent = false,
          bool saved = false,
          bool liked = false,
          List<String> intentions = const ['serious_relationship'],
          String? bio}) =>
      {
        'id': id,
        'display_name': name,
        'age': age,
        'city': city,
        'province': province,
        'profession': profession,
        'avatar_path': null,
        'bio': bio ?? 'A member of the Spiritual Home seeking an intentional '
            'relationship.',
        'intentions': intentions,
        'relationship_status': status ?? 'single',
        'household': household,
        'is_demo': true,
        'score': score,
        'reasons': reasons,
        'saved': saved,
        'liked': liked,
        'matched': matched,
        'interest_sent': interestSent,
        'interest_received': interestReceived,
      };

  // ------------------------------------------------------------------
  // RPC
  // ------------------------------------------------------------------
  @override
  Future<dynamic> rpc(String fn, {Map<String, dynamic>? params}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    params ??= const {};
    switch (fn) {
      // Account
      case 'my_permissions':
        return <String>[];
      case 'expire_my_sanctions':
        return null;
      case 'export_my_data':
        return {
          'profile': _profiles[me],
          'partner_preferences': _partnerPrefs.isEmpty ? null : _partnerPrefs,
          'exported_at': _now(),
        };

      // Discovery
      case 'get_recommendations':
        final lim = (params['lim'] as int?) ?? 12;
        final off = (params['off'] as int?) ?? 0;
        final all = [
          _card('u-1', 'Thabo Nkosi', 31, 'Johannesburg', 'Gauteng',
              'Engineer',
              score: 86,
              reasons: [
                'You both want a serious relationship',
                'Same province',
                'Shared value: family',
              ],
              matched: true),
          _card('u-5', 'Kgosi Maluleke', 34, 'Pretoria', 'Gauteng',
              'Accountant',
              score: 74,
              reasons: ['Same intentions', 'Both want children']),
          _card('u-6', 'Andile Zulu', 29, 'Durban', 'KwaZulu-Natal', 'Nurse',
              score: 69, reasons: ['Shared language: isiZulu']),
          _card('u-7', 'Pieter Botha', 36, 'Cape Town', 'Western Cape',
              'Chef', score: 61),
        ];
        final rows = all.skip(off).take(lim).toList();
        return {
          'gate': {
            'ok': true,
            'visible_to_others': true,
            'completion': 82,
            'min_completion': 60,
          },
          'rows': rows,
          'disclaimer': _settings['matching.disclaimer']!['value'],
        };
      case 'search_members':
        final f = (params['f'] as Map?) ?? const {};
        var rows = [
          _card('u-1', 'Thabo Nkosi', 31, 'Johannesburg', 'Gauteng', 'Engineer',
              matched: true),
          _card('u-2', 'Zanele Mbeki', 30, 'Soweto', 'Gauteng', 'Social worker',
              interestReceived: 'i-2'),
          _card('u-3', 'Sipho Khumalo', 41, 'Pietermaritzburg',
              'KwaZulu-Natal', 'Business owner',
              status: 'married',
              household: {'wives': 2, 'seeking': true},
              intentions: ['traditional_family']),
          _card('u-4', 'Lerato Khumalo', 28, 'Bloemfontein', 'Free State',
              'Pharmacist', interestSent: true),
          _card('u-6', 'Andile Zulu', 29, 'Durban', 'KwaZulu-Natal', 'Nurse'),
        ];
        final prov = (f['province'] as String?) ?? '';
        if (prov.isNotEmpty) {
          rows = rows.where((r) => r['province'] == prov).toList();
        }
        final total = rows.length;
        final page = (params['page'] as int?) ?? 1;
        final pageSize = 10;
        final start = (page - 1) * pageSize;
        return {
          'gate': {'ok': true, 'visible_to_others': true},
          'rows': start < rows.length ? rows.sublist(start) : <dynamic>[],
          'total': total,
          'page_size': pageSize,
        };
      case 'get_member_profile_guarded':
        final target = params['target'] as String?;
        return _card(target ?? 'u-1', 'Thabo Nkosi', 31, 'Johannesburg',
            'Gauteng', 'Engineer',
            score: 86,
            reasons: ['Same province', 'Shared intentions'],
            bio: 'I am an engineer who values steady growth, prayer and '
                'family. I enjoy hiking and cooking on weekends.');
      case 'get_compatibility':
        return {
          'score': 86,
          'reasons': [
            'You both want a serious relationship',
            'Same province',
            'Shared value: family',
            'Both want children',
            'Similar lifestyles',
          ],
        };
      case 'send_interest':
        return _uuid();
      case 'respond_interest':
        return null;
      case 'withdraw_interest':
        return null;
      case 'toggle_like':
        return true;
      case 'toggle_save':
        return true;
      case 'set_pass':
        return null;
      case 'block_member':
      case 'unblock_member':
        return null;
      case 'my_blocked':
        return <dynamic>[];
      case 'my_connections':
        return {
          'received': [
            _card('u-2', 'Zanele Mbeki', 30, 'Soweto', 'Gauteng',
                'Social worker', interestReceived: 'i-2'),
          ],
          'sent': [
            _card('u-4', 'Lerato Khumalo', 28, 'Bloemfontein', 'Free State',
                'Pharmacist', interestSent: true),
          ],
          'matches': [
            _card('u-1', 'Thabo Nkosi', 31, 'Johannesburg', 'Gauteng',
                'Engineer', matched: true),
          ],
          'saved': <dynamic>[],
          'liked_me': [
            _card('u-6', 'Andile Zulu', 29, 'Durban', 'KwaZulu-Natal', 'Nurse'),
          ],
          'hidden': <dynamic>[],
          'history': <dynamic>[],
        };
      case 'my_match_summary':
        return {
          'interests_received': 1,
          'interests_sent': 1,
          'matches': 1,
          'likes_received': 1,
        };
      case 'end_match':
        return null;

      // Messaging
      case 'my_conversations':
        return [
          {
            'id': 'c-1',
            'other_id': 'u-1',
            'other_name': 'Thabo Nkosi',
            'other_avatar_path': null,
            'last_kind': 'text',
            'last_body': 'Which session was it?',
            'last_sender_id': me,
            'last_at': _ago(const Duration(minutes: 38)),
            'unread': 0,
            'closed': false,
          },
        ];
      case 'get_conversation':
        return {
          'id': params['conv'],
          'closed': false,
          'other': {
            'id': 'u-1',
            'display_name': 'Thabo Nkosi',
            'avatar_path': null,
            'last_read_at': _ago(const Duration(minutes: 30)),
          },
          'reactions': ['❤️', '🙏', '😊', '😂', '👍', '🌿'],
          'video_enabled': true,
          'max_voice_seconds': 120,
          'max_video_seconds': 60,
          'relationship': {
            'id': 'r-1',
            'stage': 'talking',
            'timeline': [
              {'stage': 'talking', 'at': _ago(const Duration(days: 6))},
            ],
            'gate': {
              'ok': false,
              'target': 'dating',
              'target_label': 'Dating',
              'reasons': ['consultation_needed'],
            },
          },
        };
      case 'send_message':
        final m = {
          'id': _uuid(),
          'conversation_id': params['conv'],
          'sender_id': me,
          'kind': params['kind'],
          'body': params['body'],
          'media_path': params['media_path'],
          'media_seconds': params['media_seconds'],
          'created_at': _now(),
          'deleted_at': null,
        };
        _messages.add(m);
        _notify('messages', 'INSERT', m);
        // Demo partner reply for text messages.
        if (params['kind'] == 'text') {
          final convId = params['conv'];
          unawaited(Future<void>.delayed(const Duration(seconds: 2), () {
            final reply = {
              'id': _uuid(),
              'conversation_id': convId,
              'sender_id': 'u-1',
              'kind': 'text',
              'body': 'Thank you for sharing that. It means a lot.',
              'media_path': null,
              'media_seconds': null,
              'created_at': _now(),
              'deleted_at': null,
            };
            _messages.add(reply);
            _notify('messages', 'INSERT', reply);
          }));
        }
        return m['id'];
      case 'mark_conversation_read':
        return null;
      case 'react_message':
        return null;
      case 'delete_message':
        final id = params['msg'] as String?;
        for (final m in _messages) {
          if (m['id'] == id) {
            m['deleted_at'] = _now();
            _notify('messages', 'UPDATE', m);
          }
        }
        return null;
      case 'report_member':
        return _uuid();
      case 'mark_notifications_read':
        for (final n in _notifications) {
          n['read_at'] = _now();
        }
        return null;

      // Relationships
      case 'my_relationships':
        return {
          'active': [
            {
              'id': 'r-1',
              'stage': 'talking',
              'partner': {
                'id': 'u-1',
                'display_name': 'Thabo Nkosi',
                'avatar_path': null,
              },
              'timeline': [
                {'stage': 'talking', 'at': _ago(const Duration(days: 6))},
              ],
              'gate': {
                'ok': false,
                'target': 'dating',
                'target_label': 'Dating',
                'reasons': ['consultation_needed'],
              },
            },
          ],
          'past': <dynamic>[],
          'marital_status': 'single',
        };
      case 'my_relationship_state':
        return {
          'id': params['rel_id'],
          'stage': 'talking',
          'gate': {
            'ok': false,
            'target': 'dating',
            'target_label': 'Dating',
            'reasons': ['consultation_needed'],
          },
          'timeline': [
            {'stage': 'talking', 'at': _ago(const Duration(days: 6))},
          ],
        };
      case 'propose_stage':
        return _uuid();
      case 'respond_stage_proposal':
      case 'withdraw_stage_proposal':
      case 'pause_relationship':
      case 'resume_relationship':
        return null;

      // Consultation (member)
      case 'my_consultation':
        return {
          'eligibility': {'eligible': false, 'until': null},
          'approved_stage': null,
          'approved_label': null,
          'request': {
            'id': 'cr-1',
            'relationship_id': params['rel_id'],
            'status': 'awaiting_partner',
            'mode': 'in_person',
            'availability': 'Weekends',
            'note': 'We would like guidance before dating.',
            'requester_id': me,
            'consultant_name': null,
            'sessions': <dynamic>[],
          },
        };
      case 'request_consultation':
        return _uuid();
      case 'respond_consultation':
      case 'cancel_consultation':
      case 'request_reschedule':
        return null;

      // Households
      case 'my_household':
        return {
          'eligibility': {'eligible': false, 'reason': 'not_married'},
          'as_head': false,
          'wives_on_record': <dynamic>[],
          'household': null,
        };
      case 'household_eligibility':
        return {'eligible': false, 'reason': 'not_married'};
      case 'save_household':
        return _uuid();
      case 'submit_household':
      case 'respond_household_consent':
      case 'withdraw_household_consent':
      case 'close_household':
        return null;
      case 'household_directory':
        return [
          _card('u-3', 'Sipho Khumalo', 41, 'Pietermaritzburg',
              'KwaZulu-Natal', 'Business owner',
              status: 'married',
              household: {'wives': 2, 'seeking': true},
              intentions: ['traditional_family']),
        ];
      case 'household_candidates':
        return <dynamic>[];
      case 'send_household_interest':
        return _uuid();

      // Community
      case 'get_feed':
        final before = params['before'] as String?;
        var rows = _posts.toList();
        if (before != null) {
          rows = rows.where((p) => (p['created_at'] as String).compareTo(before) < 0).toList();
        }
        return {
          'rows': rows,
          'next_before': null,
        };
      case 'get_post':
        final id = params['post'] as String?;
        final p = _posts.firstWhere((e) => e['id'] == id);
        return {
          ...p,
          'comments': _comments.where((c) => c['post_id'] == id).toList(),
        };
      case 'story_ring':
        return [
          {
            'author_id': me,
            'author_name': 'Naledi Dlamini',
            'mine': true,
            'seen': true,
            'stories': _stories.where((s) => s['author_id'] == me).toList(),
          },
          {
            'author_id': 'u-2',
            'author_name': 'Zanele Mbeki',
            'mine': false,
            'seen': false,
            'stories': _stories.where((s) => s['author_id'] == 'u-2').toList(),
          },
        ];
      case 'create_post':
        final p = {
          'id': _uuid(),
          'author_id': me,
          'author_name': 'Naledi Dlamini',
          'body': params['body'],
          'media_path': params['media'],
          'created_at': _now(),
          'comment_count': 0,
          'mine': true,
        };
        _posts.insert(0, p);
        return p['id'];
      case 'edit_post':
        return null;
      case 'delete_post':
        _posts.removeWhere((p) => p['id'] == params?['post']);
        return null;
      case 'add_comment':
        final c = {
          'id': _uuid(),
          'post_id': params['post'],
          'author_id': me,
          'author_name': 'Naledi Dlamini',
          'body': params['body'],
          'created_at': _now(),
        };
        _comments.add(c);
        return c['id'];
      case 'delete_comment':
        _comments.removeWhere((c) => c['id'] == params?['comment']);
        return null;
      case 'react_post':
        return null;
      case 'create_story':
        final s = {
          'id': _uuid(),
          'author_id': me,
          'author_name': 'Naledi Dlamini',
          'body': params['body'],
          'background': params['background'],
          'media_path': params['media'],
          'created_at': _now(),
          'seen': true,
          'viewers': 0,
          'mine': true,
        };
        _stories.add(s);
        return s['id'];
      case 'delete_story':
        _stories.removeWhere((s) => s['id'] == params?['story']);
        return null;
      case 'view_story':
        return null;
      case 'story_viewers':
        return [
          {'user_id': 'u-2', 'display_name': 'Zanele Mbeki'},
        ];
      case 'report_content':
        return _uuid();

      // Safety
      case 'my_standing':
        return {
          'account_status': 'active',
          'active_strikes': 0,
          'strike_window_days': 90,
          'strikes_to_restrict': 3,
          'strikes_to_suspend': 5,
          'sanctions': <dynamic>[],
        };
      case 'submit_appeal':
        return _uuid();

      // Conferences
      case 'conference_list':
        return [
          {
            'id': 'conf-1',
            'kind': 'Conference',
            'title': 'Love Life Conference 2026',
            'summary': 'A gathering on relationships, courtship and family.',
            'format': 'In person and online',
            'city': 'Johannesburg',
            'province': 'Gauteng',
            'starts_at': '2026-11-06T08:00:00+00:00',
            'ends_at': '2026-11-08T17:00:00+00:00',
            'capacity': 300,
            'seats_left': 42,
            'audience': 'Members',
            'my_registration': 'registered',
            'speakers': [
              {'name': 'Pastor E. Mthembu', 'title': 'Founder'},
            ],
            'recordings': 2,
          },
          {
            'id': 'conf-2',
            'kind': 'Seminar',
            'title': 'Preparing for Courtship',
            'summary': 'A practical seminar for declared relationships.',
            'format': 'Online',
            'city': null,
            'province': null,
            'starts_at': '2026-10-17T17:00:00+00:00',
            'ends_at': '2026-10-17T19:00:00+00:00',
            'capacity': null,
            'seats_left': null,
            'audience': 'Members',
            'my_registration': null,
            'speakers': [
              {'name': 'Sis. N. Dube', 'title': 'Consultant'},
            ],
            'recordings': 0,
          },
        ];
      case 'conference_detail':
        final id = params['conf'] as String?;
        final list = await rpc('conference_list') as List;
        final base = Map<String, dynamic>.from(
            list.firstWhere((c) => (c as Map)['id'] == id));
        return {
          ...base,
          'description':
              'The Love Life Conference brings members together for '
              'teaching, fellowship and honest conversation about '
              'relationships that honour God and family.',
          'venue': 'Grace Hall, Johannesburg',
          'registration_closes_at': '2026-10-30T00:00:00+00:00',
          'sessions': [
            {
              'id': 'sess-1',
              'title': 'Opening word: relationships with purpose',
              'description': 'Setting the tone for the conference.',
              'starts_at': '2026-11-06T09:00:00+00:00',
              'ends_at': '2026-11-06T10:30:00+00:00',
              'speaker': {
                'name': 'Pastor E. Mthembu',
                'title': 'Founder',
                'bio': 'Shepherd of The Revelation Spiritual Home Kingdom.',
              },
              'live_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
              'recording_url': null,
              'my_questions': [
                {
                  'id': 'q-1',
                  'body': 'How do we involve families early?',
                  'anonymous': true,
                  'answered': false,
                },
              ],
            },
          ],
          'waitlist_position': null,
        };
      case 'register_conference':
        return 'registered';
      case 'cancel_registration':
        return null;
      case 'ask_question':
        return _uuid();
      case 'live_now':
        return [
          {
            'session_id': 'sess-1',
            'conference_id': 'conf-1',
            'title': 'Opening word: relationships with purpose',
            'conference_title': 'Love Life Conference 2026',
            'registered': true,
          },
        ];
      case 'live_room':
        return {
          'session_id': params['session'],
          'title': 'Opening word: relationships with purpose',
          'conference_id': 'conf-1',
          'conference': {'id': 'conf-1', 'title': 'Love Life Conference 2026'},
          'status': 'live',
          'kind': 'youtube',
          'allowed': true,
          'can_run': false,
          'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'room': null,
          'jitsi_domain': null,
          'recording_url': null,
          'me': {'id': me, 'display_name': 'Naledi Dlamini'},
          'chat': _liveChat,
        };
      case 'send_live_chat':
        final c = {
          'id': _uuid(),
          'author_id': me,
          'author_name': 'Naledi Dlamini',
          'body': params['body'],
          'created_at': _now(),
          'is_speaker': false,
        };
        _liveChat.add(c);
        _notify('conference_chat', 'INSERT', c);
        return c['id'];
      case 'hide_live_chat':
        return null;
      case 'my_speaking':
        return <dynamic>[];
      case 'update_my_session':
      case 'go_live':
      case 'end_live':
        return null;

      // Announcements
      case 'my_announcements':
        return [
          {
            'id': 'a-1',
            'title': 'Love Life Conference registrations are open',
            'body': 'Register early to receive your programme and live '
                'links. Seats are limited for in-person attendance.',
            'tone': 'celebration',
            'link_url': '/conferences',
            'link_label': 'See conferences',
          },
        ];
      case 'dismiss_announcement':
        return null;

      // Consultant (role-gated)
      case 'consultation_dashboard':
        return {
          'assigner': false,
          'handles': false,
          'mine': <dynamic>[],
          'recent': <dynamic>[],
          'queue': <dynamic>[],
          'in_progress': <dynamic>[],
          'stats': {
            'waiting': 0,
            'in_progress': 0,
            'approved_90d': 0,
            'decided_90d': 0,
          },
        };
      case 'get_consultation':
        return {'id': params['req'], 'status': 'awaiting_assignment'};
      case 'list_consultants':
        return <dynamic>[];
      case 'assign_consultant':
      case 'schedule_session':
      case 'update_session':
      case 'add_consultation_note':
      case 'record_outcome':
      case 'hand_back_consultation':
        return null;
      case 'households_for_review':
        return <dynamic>[];
      case 'review_household':
        return null;

      default:
        throw FakeRpcError('Unknown RPC in fake backend: $fn');
    }
  }

  // ------------------------------------------------------------------
  // Tables
  // ------------------------------------------------------------------
  @override
  Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, dynamic>? equals,
    Map<String, dynamic>? lessThan,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    switch (table) {
      case 'profiles':
        return [Map<String, dynamic>.from(_profiles[me]!)];
      case 'partner_preferences':
        return _partnerPrefs.isEmpty ? [] : [_partnerPrefs];
      case 'profile_field_defaults':
        return [
          {'field_key': 'avatar', 'default_visibility': 'all'},
          {'field_key': 'full_name', 'default_visibility': 'all'},
          {'field_key': 'contact', 'default_visibility': 'me'},
        ];
      case 'profile_field_visibility':
        return _visibility.values.toList();
      case 'app_settings':
        final key = equals?['key'] as String?;
        final rows = <Map<String, dynamic>>[];
        _settings.forEach((k, v) {
          if (key == null || k == key) rows.add({'key': k, ...v});
        });
        return rows;
      case 'notifications':
        return _notifications.toList();
      case 'messages':
        final conv = equals?['conversation_id'] as String?;
        final before = lessThan?['created_at'] as String?;
        var rows = _messages
            .where((m) => conv == null || m['conversation_id'] == conv)
            .where((m) =>
                before == null || (m['created_at'] as String).compareTo(before) < 0)
            .toList();
        rows.sort((a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String));
        if (limit != null && rows.length > limit) {
          rows = rows.sublist(0, limit);
        }
        return rows;
      case 'interests':
        return [
          {'id': 'i-2', 'recipient_id': me, 'status': 'pending'},
        ];
      case 'consultation_requests':
        return [
          {
            'id': 'cr-1',
            'relationship_id': 'r-1',
            'status': 'awaiting_partner',
          },
        ];
      case 'user_roles':
        return <Map<String, dynamic>>[];
      default:
        return <Map<String, dynamic>>[];
    }
  }

  @override
  Future<Map<String, dynamic>?> selectOne(
    String table, {
    Map<String, dynamic>? equals,
  }) async {
    final rows = await select(table, equals: equals, limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    Map<String, dynamic>? equals,
  }) async {
    if (table == 'profiles') {
      _profiles[me]!.addAll(values);
    }
  }

  @override
  Future<void> upsert(String table, Map<String, dynamic> values) async {
    if (table == 'partner_preferences') {
      _partnerPrefs.addAll(values);
    } else if (table == 'profile_field_visibility') {
      final key = values['field_key'] as String;
      _visibility[key] = {...values, 'user_id': me};
    }
  }

  @override
  Future<void> delete(String table, Map<String, dynamic> equals) async {}

  // ---- Storage (signed URLs are data: URIs in demo mode) ----
  @override
  Future<String> signedUrl(String bucket, String path, int expiresIn) async {
    return 'fake://storage/$bucket/$path';
  }

  @override
  Future<Map<String, String>> signedUrls(
    String bucket,
    List<String> paths,
    int expiresIn,
  ) async {
    return {for (final p in paths) p: 'fake://storage/$bucket/$p'};
  }

  @override
  Future<void> uploadBinary(
    String bucket,
    String path,
    Uint8List data, {
    required String contentType,
    bool upsert = false,
  }) async {
    _storage['$bucket/$path'] = contentType;
  }

  @override
  Future<void> removeObjects(String bucket, List<String> paths) async {
    for (final p in paths) {
      _storage.remove('$bucket/$p');
    }
  }

  // ---- Auth (local demo session) ----
  @override
  String? get userId => _userId;

  @override
  String? get userEmail => 'naledi@demo.isosha.invalid';

  @override
  bool get signedIn => _userId != null;

  final StreamController<void> _authCtl = StreamController.broadcast();

  @override
  Stream<void> get authChanges => _authCtl.stream;

  @override
  Future<void> refreshAuth() async {}

  @override
  Future<AuthOutcome> signIn(String email, String password) async {
    if (password.length < 6) {
      return const AuthOutcome(ok: false, code: 'invalid_credentials');
    }
    _userId = me;
    _authCtl.add(null);
    return AuthOutcome.success;
  }

  @override
  Future<AuthOutcome> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    return AuthOutcome.success;
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    _authCtl.add(null);
  }

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<AuthOutcome> updatePassword(String newPassword) async =>
      AuthOutcome.success;

  @override
  Future<bool> requiresAal2() async => false;

  @override
  Future<List<MfaFactor>> listMfaFactors() async => const [];

  @override
  Future<AuthOutcome> verifyMfa(String factorId, String code) async =>
      code.length == 6
          ? AuthOutcome.success
          : const AuthOutcome(ok: false, code: 'mfa');

  @override
  Future<MfaEnrollment> enrollTotp() async => MfaEnrollment(
        factorId: 'factor-demo',
        secret: 'JBSWY3DPEHPK3PXP',
        uri: 'otpauth://totp/Isosha%20Esosheni:demo?secret=JBSWY3DPEHPK3PXP',
      );

  @override
  Future<AuthOutcome> unenrollMfa(String factorId) async =>
      AuthOutcome.success;

  @override
  Future<AuthOutcome?> handleAuthDeepLink(Uri uri) async =>
      AuthOutcome.success;

  // ---- Realtime (in-memory bus) ----
  @override
  CancelWatch watch(
    String table,
    WatchEvent event,
    String? filter,
    void Function(Map<String, dynamic>, Map<String, dynamic>) onEvent,
  ) {
    final sub = _FakeSub(table, event, filter, onEvent);
    _subs.add(sub);
    return () => _subs.remove(sub);
  }

  void _notify(String table, String event, Map<String, dynamic> record) {
    for (final s in List.of(_subs)) {
      if (s.table != table) continue;
      if (s.event == WatchEvent.insert && event != 'INSERT') continue;
      if (s.event == WatchEvent.update && event != 'UPDATE') continue;
      if (s.filter != null) {
        final parts = s.filter!.split('=eq.');
        if (parts.length == 2 && record[parts[0]]?.toString() != parts[1]) {
          continue;
        }
      }
      s.onEvent(record, const {});
    }
  }

  @override
  Future<void> dispose() async {}
}

class _FakeSub {
  _FakeSub(this.table, this.event, this.filter, this.onEvent);
  final String table;
  final WatchEvent event;
  final String? filter;
  final void Function(Map<String, dynamic>, Map<String, dynamic>) onEvent;
}

class FakeRpcError implements Exception {
  FakeRpcError(this.message);
  final String message;
  @override
  String toString() => message;
}
