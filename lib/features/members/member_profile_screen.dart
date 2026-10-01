import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/panel.dart';
import '../../core/widgets/report_sheet.dart';
import '../../data/models/member.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  MemberCardData? _data;
  Compatibility? _compat;
  String? _error;
  String? _videoUrl;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = context.read(discoveryRepoProvider);
      final me = context.read(sessionProvider).me;
      final data = await repo.memberProfile(widget.id);
      final compat = await repo.compatibility(widget.id);
      String? video;
      if ((data.videoPath ?? '').isNotEmpty) {
        try {
          video = await context
              .read(accountRepoProvider)
              .videoUrl(data.videoPath);
        } catch (_) {
          video = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _data = data;
        _compat = compat;
        _videoUrl = video;
      });
      void _u() => me.hashCode;
      _u();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
    }
  }

  Future<void> _report() async {
    final repo = context.read(discoveryRepoProvider);
    await ReportSheet.show(
      context,
      title: 'Report ${_data?.displayName ?? 'member'}',
      onSubmit: (category, details) async {
        try {
          await repo.reportMember(widget.id, category, details);
          return null;
        } catch (e) {
          return friendlyError(e);
        }
      },
    );
  }

  Future<void> _block() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block ${_data?.displayName ?? 'this member'}?',
            style: T.headline.copyWith(fontSize: 21)),
        content: const Text(
          'Blocking hides each of you from the other entirely.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          DangerButton(
              label: 'Block',
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await context.read(discoveryRepoProvider).block(widget.id);
      if (mounted) {
        setState(() => _blocked = true);
        context.go('/discover');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(sessionProvider).me;
    final own = me?.id == widget.id;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _data == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (own)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'This is how your profile appears to other members.',
                          style: T.small,
                        ),
                      ),
                    MemberImage(
                      name: _data!.displayName,
                      url: ref
                          .watch(avatarUrlProvider(_data!.avatarPath))
                          .valueOrNull,
                      cacheKey: _data!.avatarPath,
                      aspect: 4 / 5,
                    ),
                    const SizedBox(height: 14),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ScoreBadge(score: _compat?.score ?? _data!.score),
                          if ((_compat?.reasons.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 10),
                            for (final r in _compat!.reasons.take(5))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 15, color: C.sage),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(r,
                                          style: T.small.copyWith(
                                              color: C.ink)),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              _compat?.disclaimer ??
                                  'Scores are a starting point for '
                                  'conversation, not a verdict.',
                              style: T.small.copyWith(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(_data!.displayName, style: T.display),
                    Text(
                      [
                        if (_data!.age != null) '${_data!.age}',
                        if ((_data!.city ?? '').isNotEmpty) _data!.city,
                        if ((_data!.province ?? '').isNotEmpty)
                          _data!.province,
                        if ((_data!.profession ?? '').isNotEmpty)
                          _data!.profession,
                      ].join(', '),
                      style: T.small,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if ((_data!.relationshipStatus ?? 'single') !=
                            'single')
                          ChipSmall(maritalLabel(_data!.relationshipStatus),
                              tone: ChipTone.bronze),
                        for (final i in _data!.intentions)
                          ChipSmall(intentionLabel(i)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MemberCardActionsRow(
                      data: _data!,
                      onChanged: _load,
                    ),
                    if (_videoUrl != null) ...[
                      const SizedBox(height: 14),
                      _IntroVideo(url: _videoUrl!),
                    ],
                    const SizedBox(height: 14),
                    if ((_data!.bio ?? '').isNotEmpty)
                      _section('About', _data!.bio!),
                    const SizedBox(height: 14),
                    if (!own)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          QuietButton(
                              label: 'Report', onPressed: _report),
                          const SizedBox(width: 8),
                          DangerButton(label: 'Block', onPressed: _block),
                        ],
                      ),
                    if (_blocked)
                      const Text('Member blocked.', style: TextStyle(fontSize: 13)),
                  ],
                ),
    );
  }

  Widget _section(String title, String body) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: T.headline.copyWith(fontSize: 20)),
          const SizedBox(height: 6),
          Text(body, style: T.body.copyWith(fontSize: 14.5)),
        ],
      ),
    );
  }
}

class MemberCardActionsRow extends StatelessWidget {
  const MemberCardActionsRow({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final MemberCardData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = context.read(discoveryRepoProvider);
    return MemberCard(
      data: data,
      variant: CardActionVariant.discover,
      onSendInterest: () async {
        try {
          await repo.sendInterest(data.id);
          onChanged();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(friendlyError(e))));
          }
        }
      },
      onLike: () async {
        await repo.toggleLike(data.id);
        onChanged();
      },
      onSave: () async {
        await repo.toggleSave(data.id);
        onChanged();
      },
      onPass: () async {
        await repo.setPass(data.id, true);
        onChanged();
      },
    );
  }
}

class _IntroVideo extends StatefulWidget {
  const _IntroVideo({required this.url});
  final String url;

  @override
  State<_IntroVideo> createState() => _IntroVideoState();
}

class _IntroVideoState extends State<_IntroVideo> {
  VideoPlayerController? _ctl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.url.startsWith('fake://')) {
      _failed = true;
      return;
    }
    _init();
  }

  Future<void> _init() async {
    try {
      final ctl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await ctl.initialize();
      if (mounted) setState(() => _ctl = ctl);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _ctl == null) {
      return Panel(
        child: Text('Introduction video', style: T.bodyStrong),
      );
    }
    return AspectRatio(
      aspectRatio: _ctl!.value.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VideoPlayer(_ctl!),
      ),
    );
  }
}
