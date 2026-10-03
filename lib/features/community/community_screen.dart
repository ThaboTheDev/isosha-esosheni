import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/buttons.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/panel.dart';
import '../../core/widgets/report_sheet.dart';
import '../../data/models/community.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final List<Post> _posts = [];
  List<StoryGroup> _stories = const [];
  String? _error;
  bool _loading = true;
  String? _nextBefore;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read(communityRepoProvider);
      final feed = await repo.feed();
      final stories = await repo.storyRing().catchError((_) => <StoryGroup>[]);
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(feed.rows);
        _nextBefore = feed.nextBefore;
        _stories = stories;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restricted = ref.watch(sessionProvider).restricted;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StoryRow(
            groups: _stories,
            onChanged: _load,
          ),
          const SizedBox(height: 14),
          if (!restricted) _Composer(onPosted: _load),
          if (restricted)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.crimson100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Your account is restricted, so you can read but not post '
                'or comment.',
                style: TextStyle(fontSize: 13, color: C.crimson600),
              ),
            ),
          const SizedBox(height: 14),
          if (_loading)
            const SkeletonList(count: 3)
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else if (_posts.isEmpty)
            const EmptyState(
              message: 'Nothing shared yet. Be the first to encourage '
                  'someone today.',
            ),
          for (final p in _posts)
            PostCard(post: p, onChanged: _load),
          if (_nextBefore != null)
            Center(
              child: TextButton(
                onPressed: _more,
                child: const Text('Earlier posts'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _more() async {
    try {
      final res = await context
          .read(communityRepoProvider)
          .feed(before: _nextBefore);
      if (!mounted) return;
      setState(() {
        _posts.addAll(res.rows);
        _nextBefore = res.nextBefore;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({required this.groups, required this.onChanged});

  final List<StoryGroup> groups;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _mineTile(context),
          for (final g in groups.where((g) => !g.mine))
            _ring(context, g),
        ],
      ),
    );
  }

  Widget _mineTile(BuildContext context) {
    final mine = groups.where((g) => g.mine).toList();
    return GestureDetector(
      onTap: () {
        if (mine.isNotEmpty && mine.first.stories.isNotEmpty) {
          StoryViewer.show(context, mine.first.stories, onChanged: onChanged);
        } else {
          StoryComposer.show(context, onChanged: onChanged);
        }
      },
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              children: [
                Avatar(
                    name: context
                            .read(sessionProvider)
                            .me
                            ?.preferredName ??
                        'You',
                    size: 56),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: C.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 16, color: C.royal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Your story',
                style: TextStyle(fontSize: 11, color: C.muted)),
          ],
        ),
      ),
    );
  }

  Widget _ring(BuildContext context, StoryGroup g) {
    return GestureDetector(
      onTap: () => StoryViewer.show(context, g.stories, onChanged: onChanged),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: g.seen ? C.line : C.crimson,
                  width: 2.5,
                ),
              ),
              child: Avatar(name: g.authorName, size: 52),
            ),
            const SizedBox(height: 4),
            Text(
              g.authorName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: C.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({this.onPosted});
  final VoidCallback? onPosted;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final _body = TextEditingController();
  XFile? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final body = _body.text.trim();
    if (body.isEmpty && _photo == null) return;
    if (body.length > 3000) return;
    setState(() => _busy = true);
    try {
      final repo = context.read(communityRepoProvider);
      String? mediaPath;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        if (bytes.lengthInBytes > 8 * 1024 * 1024) {
          throw Exception('Photos can be up to 8 MB.');
        }
        final meId = context.read(backendProvider).userId ?? 'me';
        final ext = _photo!.name.split('.').last.toLowerCase();
        mediaPath = await repo.uploadPhoto(
          meId,
          bytes,
          ext: ext,
          contentType: _photo!.mimeType ?? 'image/$ext',
        );
      }
      await repo.createPost(body, mediaPath: mediaPath);
      _body.clear();
      setState(() => _photo = null);
      widget.onPosted?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _body,
            maxLines: 3,
            maxLength: 3000,
            decoration: const InputDecoration(
              hintText: 'Share a reflection, a blessing or an encouragement',
              border: InputBorder.none,
              filled: false,
            ),
          ),
          if (_photo != null)
            Chip(
              label: Text(_photo!.name, style: const TextStyle(fontSize: 12)),
              onDeleted: () => setState(() => _photo = null),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final f = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1600,
                    imageQuality: 85,
                  );
                  if (f != null) setState(() => _photo = f);
                },
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Add photo', style: TextStyle(fontSize: 13)),
              ),
              GoldButton(
                label: 'Share',
                busy: _busy,
                onPressed: _post,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.onChanged});

  final Post post;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final meId = context.read(backendProvider).userId;
    final myReaction = post.reactions.entries
        .firstWhere((e) => e.value.contains(meId), orElse: () => const MapEntry('', []))
        .key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.hidden)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.rust100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Hidden by a moderator and visible only to you: '
                  '${post.hiddenReason}',
                  style: const TextStyle(fontSize: 12.5, color: C.rust),
                ),
              ),
            Row(
              children: [
                Avatar(name: post.authorName, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: post.authorId == null
                            ? null
                            : () => context.go('/members/${post.authorId}'),
                        child: Text(post.authorName ?? 'Member',
                            style: T.bodyStrong.copyWith(fontSize: 14.5)),
                      ),
                      Text(
                        '${Dates.timeAgo(DateTime.parse(post.createdAt))}'
                        '${post.editedAt != null ? ', edited' : ''}',
                        style: T.small.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _menu(context, v),
                  itemBuilder: (_) => [
                    if (post.mine)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (post.mine)
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    if (!post.mine)
                      const PopupMenuItem(value: 'report', child: Text('Report')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.body, style: T.body.copyWith(fontSize: 14.5)),
            if (post.mediaPath != null) ...[
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: context
                    .read(communityRepoProvider)
                    .communityMediaUrl(post.mediaPath),
                builder: (ctx, snap) => snap.data == null
                    ? const SizedBox.shrink()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(snap.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined)),
                      ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final opt in post.reactionOptions)
                  _reactionChip(context, opt, opt == myReaction),
              ],
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => context.go('/community/p/${post.id}'),
              child: Text(
                '${post.commentCount} comments',
                style: T.small.copyWith(fontSize: 12.5, color: C.royal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reactionChip(BuildContext context, String emoji, bool mine) {
    final count = post.reactions[emoji]?.length ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () async {
        try {
          await context
              .read(communityRepoProvider)
              .reactPost(post.id, mine ? null : emoji);
          onChanged();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(friendlyError(e))));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: mine ? C.plum100 : C.plum50,
          border: Border.all(color: mine ? C.royal : C.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          count > 0 ? '$emoji $count' : emoji,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, String v) async {
    final repo = context.read(communityRepoProvider);
    switch (v) {
      case 'edit':
        final ctl = TextEditingController(text: post.body);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Edit post'),
            content: TextField(
              controller: ctl,
              maxLines: 5,
              maxLength: 3000,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save')),
            ],
          ),
        );
        if (ok == true) {
          try {
            await repo.editPost(post.id, ctl.text.trim());
            onChanged();
          } catch (e) {
            _toast(context, e);
          }
        }
      case 'delete':
        try {
          await repo.deletePost(post.id);
          onChanged();
        } catch (e) {
          _toast(context, e);
        }
      case 'report':
        await ReportSheet.show(
          context,
          title: 'Report post',
          onSubmit: (category, details) async {
            try {
              await repo.reportContent('post', post.id, category, details);
              return null;
            } catch (e) {
              return friendlyError(e);
            }
          },
        );
    }
  }

  void _toast(BuildContext context, Object e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(friendlyError(e))));
  }
}

/// Full-screen story viewer with progress segments.
class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.stories, this.onChanged});

  final List<Story> stories;
  final VoidCallback? onChanged;

  static void show(BuildContext context, List<Story> stories,
      {VoidCallback? onChanged}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StoryViewer(stories: stories, onChanged: onChanged),
    ));
  }

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _view();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _view() {
    _timer?.cancel();
    final s = widget.stories[_index];
    context.read(communityRepoProvider).viewStory(s.id).catchError((_) => null);
    _timer = Timer(const Duration(seconds: 5), _next);
  }

  void _next() {
    if (_index < widget.stories.length - 1) {
      setState(() => _index++);
      _view();
    } else {
      Navigator.of(context).pop();
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stories[_index];
    final bg = C.storyColor(s.background);
    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTap: _next,
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < widget.stories.length; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 8),
                        color: i <= _index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Avatar(name: s.authorName, size: 34),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.authorName ?? '',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    if (s.mine)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white),
                        onPressed: () async {
                          try {
                            await context
                                .read(communityRepoProvider)
                                .deleteStory(s.id);
                            Navigator.of(context).pop();
                            widget.onChanged?.call();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(friendlyError(e))));
                            }
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              if (s.mediaPath != null)
                Expanded(
                  child: FutureBuilder<String?>(
                    future: context
                        .read(communityRepoProvider)
                        .communityMediaUrl(s.mediaPath),
                    builder: (ctx, snap) => snap.data == null
                        ? const SizedBox.shrink()
                        : Image.network(snap.data!, fit: BoxFit.contain),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        s.body ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.4,
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              if (s.mine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('${s.viewers} viewers',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Story composer: text on one of four backgrounds and/or one photo.
class StoryComposer extends StatefulWidget {
  const StoryComposer({super.key, this.onChanged});
  final VoidCallback? onChanged;

  static void show(BuildContext context, {VoidCallback? onChanged}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StoryComposer(onChanged: onChanged),
    );
  }

  @override
  State<StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends State<StoryComposer> {
  final _body = TextEditingController();
  String _background = 'royal';
  XFile? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final repo = context.read(communityRepoProvider);
      String? mediaPath;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        final meId = context.read(backendProvider).userId ?? 'me';
        final ext = _photo!.name.split('.').last.toLowerCase();
        mediaPath = await repo.uploadPhoto(meId, bytes,
            ext: ext, contentType: _photo!.mimeType ?? 'image/$ext');
      }
      await repo.createStory(_body.text.trim(), _background,
          mediaPath: mediaPath);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your story', style: T.headline),
          const SizedBox(height: 10),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: C.storyColor(_background),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _body.text.isEmpty ? 'Write below…' : _body.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'CormorantGaramond',
                      fontWeight: FontWeight.w700,
                      fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final key in ['royal', 'crimson', 'gold', 'night'])
                GestureDetector(
                  onTap: () => setState(() => _background = key),
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: C.storyColor(key),
                      shape: BoxShape.circle,
                      border: _background == key
                          ? Border.all(color: C.gold, width: 3)
                          : null,
                    ),
                  ),
                ),
              const Expanded(child: SizedBox()),
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: () async {
                  final picker = ImagePicker();
                  final f = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1600,
                      imageQuality: 85);
                  if (f != null) setState(() => _photo = f);
                },
              ),
            ],
          ),
          if (_photo != null)
            Chip(
              label: Text(_photo!.name, style: const TextStyle(fontSize: 12)),
              onDeleted: () => setState(() => _photo = null),
            ),
          TextField(
            controller: _body,
            maxLines: 2,
            maxLength: 300,
            decoration: const InputDecoration(
                hintText: 'A short word of blessing or encouragement',
                filled: true),
          ),
          const SizedBox(height: 8),
          GoldButton(label: 'Share story', busy: _busy, onPressed: _create),
        ],
      ),
    );
  }
}
