import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/completion_meter.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/panel.dart';
import '../../data/models/profile.dart';
import '../discover/discover_screen.dart' show provinces, saLanguages;

/// Photo and video management.
class ProfileMediaScreen extends ConsumerStatefulWidget {
  const ProfileMediaScreen({super.key});

  @override
  ConsumerState<ProfileMediaScreen> createState() => _ProfileMediaScreenState();
}

class _ProfileMediaScreenState extends ConsumerState<ProfileMediaScreen> {
  bool _busy = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      _toast('Profile photos can be up to 5 MB.');
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = context.read(accountRepoProvider);
      final me = context.read(sessionProvider).me!;
      final ext = f.name.split('.').last.toLowerCase();
      final old = me.avatarPath;
      final path = await repo.uploadAvatar(me.id, bytes,
          ext: ext, contentType: f.mimeType ?? 'image/$ext');
      final updated = await repo.updateProfile(me.id, {'avatar_path': path});
      context.read(sessionProvider.notifier).patchMe(updated);
      if (old != null) await repo.removeObjects('avatars', [old]);
    } catch (e) {
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final f = await picker.pickVideo(source: ImageSource.gallery);
    if (f == null) return;
    VideoPlayerController? ctl;
    try {
      ctl = VideoPlayerController.file(File(f.path));
      await ctl.initialize();
      if (ctl.value.duration.inSeconds > 120) {
        _toast('Introduction videos can be up to 120 seconds.');
        return;
      }
    } catch (_) {} finally {
      await ctl?.dispose();
    }
    final bytes = await f.readAsBytes();
    if (bytes.lengthInBytes > 100 * 1024 * 1024) {
      _toast('Videos can be up to 100 MB.');
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = context.read(accountRepoProvider);
      final me = context.read(sessionProvider).me!;
      final ext = f.name.split('.').last.toLowerCase();
      final old = me.videoPath;
      final path = await repo.uploadProfileVideo(me.id, bytes,
          ext: ext, contentType: f.mimeType ?? 'video/$ext');
      final updated = await repo.updateProfile(me.id, {'video_path': path});
      context.read(sessionProvider.notifier).patchMe(updated);
      if (old != null) await repo.removeObjects('profile-videos', [old]);
    } catch (e) {
      _toast(friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider).me;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Photo and video'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile photo', style: T.headline.copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FutureBuilder<String?>(
                      future: context
                          .read(accountRepoProvider)
                          .avatarUrl(me?.avatarPath),
                      builder: (ctx, snap) => AvatarX(
                        name: me?.preferredName,
                        url: snap.data,
                        size: 72,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        PrimaryButton(
                          label: 'Change photo',
                          busy: _busy,
                          onPressed: _pickAvatar,
                        ),
                        if (me?.avatarPath != null) ...[
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () async {
                              final old = me!.avatarPath!;
                              final updated = await context
                                  .read(accountRepoProvider)
                                  .updateProfile(me.id, {'avatar_path': null});
                              context
                                  .read(sessionProvider.notifier)
                                  .patchMe(updated);
                              await context
                                  .read(accountRepoProvider)
                                  .removeObjects('avatars', [old]);
                            },
                            child: const Text('Remove',
                                style: TextStyle(color: C.rust, fontSize: 13)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Introduction video',
                    style: T.headline.copyWith(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  'A short video of up to 120 seconds, in your own words. '
                  'MP4, WebM or MOV, up to 100 MB.',
                  style: T.small,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: me?.videoPath == null
                      ? 'Add video'
                      : 'Replace video',
                  busy: _busy,
                  onPressed: _pickVideo,
                ),
                if (me?.videoPath != null)
                  TextButton(
                    onPressed: () async {
                      final old = me!.videoPath!;
                      final updated = await context
                          .read(accountRepoProvider)
                          .updateProfile(me.id, {'video_path': null});
                      context.read(sessionProvider.notifier).patchMe(updated);
                      await context
                          .read(accountRepoProvider)
                          .removeObjects('profile-videos', [old]);
                    },
                    child: const Text('Remove',
                        style: TextStyle(color: C.rust, fontSize: 13)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AvatarX extends StatelessWidget {
  const AvatarX({this.name, this.url, this.size = 44});
  final String? name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.startsWith('fake://')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: C.plum100, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          ((name ?? 'M').trim().isNotEmpty ? name!.trim()[0] : 'M')
              .toUpperCase(),
          style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontWeight: FontWeight.w700,
              fontSize: size * 0.4,
              color: C.plum700),
        ),
      );
    }
    return ClipOval(
      child: Image.network(url!, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: C.plum100)),
    );
  }
}

/// Partner preferences.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  int _min = 18;
  int _max = 99;
  String _gender = 'any';
  List<String> _provinces = [];
  List<String> _languages = [];
  List<String> _intentions = [];
  bool _polygamy = false;
  List<String> _dealbreakers = [];
  final _notes = TextEditingController();
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await context.read(accountRepoProvider).preferences();
      if (!mounted) return;
      setState(() {
        _loaded = true;
        if (p != null) {
          _min = p.minAge;
          _max = p.maxAge;
          _gender = p.preferredGender;
          _provinces = List.of(p.preferredProvinces);
          _languages = List.of(p.preferredLanguages);
          _intentions = List.of(p.preferredIntentions);
          _polygamy = p.openToPolygamy;
          _dealbreakers = List.of(p.dealbreakers);
          _notes.text = p.notes ?? '';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = friendlyError(e);
        });
      }
    }
  }

  Future<void> _save() async {
    if (_max < _min) {
      setState(() => _error = 'Maximum age must be at least the minimum age.');
      return;
    }
    if (_notes.text.length > 1000) {
      setState(() => _error = 'Notes are limited to 1000 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final me = context.read(sessionProvider).me!;
      await context.read(accountRepoProvider).savePreferences(
            PartnerPreferences(
              minAge: _min,
              maxAge: _max,
              preferredGender: _gender,
              preferredProvinces: _provinces,
              preferredLanguages: _languages,
              preferredIntentions: _intentions,
              openToPolygamy: _polygamy,
              dealbreakers: _dealbreakers,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
            me.id,
          );
      context.read(sessionProvider.notifier).reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferences saved.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Partner preferences'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Age range: $_min – $_max',
              style: T.bodyStrong.copyWith(fontSize: 14)),
          Row(
            children: [
              Expanded(
                child: Slider(
                  min: 18,
                  max: 120,
                  value: _min.toDouble(),
                  onChanged: (v) => setState(() {
                    _min = v.round();
                    if (_max < _min) _max = _min;
                  }),
                ),
              ),
              Expanded(
                child: Slider(
                  min: 18,
                  max: 120,
                  value: _max.toDouble(),
                  onChanged: (v) => setState(() {
                    _max = v.round();
                    if (_max < _min) _min = _max;
                  }),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            value: _gender,
            items: const [
              DropdownMenuItem(value: 'female', child: Text('Female')),
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'any', child: Text('Any')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? 'any'),
            decoration:
                const InputDecoration(labelText: 'Preferred gender', filled: true),
          ),
          const SizedBox(height: 10),
          Text('Preferred provinces', style: T.bodyStrong.copyWith(fontSize: 14)),
          _chips(provinces, _provinces, (v) => setState(() => _provinces = v)),
          Text('Preferred languages', style: T.bodyStrong.copyWith(fontSize: 14)),
          _chips(saLanguages, _languages, (v) => setState(() => _languages = v)),
          Text('Preferred intentions', style: T.bodyStrong.copyWith(fontSize: 14)),
          _chips(
            intentionLabelsLocal,
            _intentions,
            (v) => setState(() => _intentions = v),
          ),
          SwitchListTile(
            value: _polygamy,
            title: const Text('Open to a polygamous family',
                style: TextStyle(fontSize: 14)),
            onChanged: (v) => setState(() => _polygamy = v),
          ),
          Text('Dealbreakers', style: T.bodyStrong.copyWith(fontSize: 14)),
          TagInput(
              tags: _dealbreakers,
              onChanged: (v) => setState(() => _dealbreakers = v)),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
                labelText: 'Anything else important to you', filled: true),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: const TextStyle(color: C.rust, fontSize: 13)),
            ),
          PrimaryButton(label: 'Save preferences', busy: _busy, onPressed: _save),
        ],
      ),
    );
  }

  Widget _chips(List<String> options, List<String> values,
      ValueChanged<List<String>> onSet) {
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
          ),
      ],
    );
  }
}

const List<String> intentionLabelsLocal = [
  'friendship',
  'serious_relationship',
  'courtship',
  'marriage',
  'future_marriage',
  'traditional_family',
  'monogamous_marriage',
  'open_to_polygamous_marriage',
];

/// Privacy controls.
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  List<FieldVisibility>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context.read(accountRepoProvider).fieldVisibility();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Privacy'),
      body: _rows == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Your first name, gender and relationship intentions are '
                  'always shown so that members can find you. Marital '
                  'status cannot be hidden, so nobody is misled about an '
                  'existing marriage.',
                  style: T.small,
                ),
                const SizedBox(height: 14),
                for (final r in _rows!)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: C.surface,
                      border: Border.all(color: C.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(r.label,
                              style: const TextStyle(fontSize: 14)),
                        ),
                        r.locked
                            ? const Text(
                                'Always visible to members',
                                style: TextStyle(
                                    fontSize: 12, color: C.muted),
                              )
                            : DropdownButton<String>(
                                value: r.visibility,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'all',
                                      child: Text('All members',
                                          style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(
                                      value: 'matches',
                                      child: Text('My matches only',
                                          style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(
                                      value: 'me',
                                      child: Text('Only me',
                                          style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (v) async {
                                  if (v == null) return;
                                  final me =
                                      context.read(sessionProvider).me!;
                                  try {
                                    await context
                                        .read(accountRepoProvider)
                                        .setVisibility(me.id, r.key, v);
                                    setState(() {
                                      _rows = [
                                        for (final row in _rows!)
                                          row.key == r.key
                                              ? row.copyWith(visibility: v)
                                              : row,
                                      ];
                                    });
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  friendlyError(e))));
                                    }
                                  }
                                },
                              ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Profile hub with horizontal pill tabs (deep links go to the pages).
class ProfileHubScreen extends ConsumerWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).me;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Your profile'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: Row(
              children: [
                CompletionMeter(me?.completionPercent ?? 0),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Completion is calculated by the platform from what '
                    'you have shared.',
                    style: T.small,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _tile(context, Icons.edit_outlined, 'Details', '/profile/edit'),
          _tile(context, Icons.photo_camera_outlined, 'Photo and video',
              '/profile/media'),
          _tile(context, Icons.tune, 'Partner preferences',
              '/profile/preferences'),
          _tile(context, Icons.lock_outline, 'Privacy', '/profile/privacy'),
          _tile(context, Icons.shield_outlined, 'Security',
              '/account/security'),
          _tile(context, Icons.block, 'Blocked members', '/account/blocked'),
          _tile(context, Icons.balance_outlined, 'Standing',
              '/account/standing'),
          _tile(context, Icons.download_outlined, 'My information',
              '/account/data'),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: C.plum700),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: C.muted),
      onTap: () => context.go(route),
    );
  }
}
