import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/loading.dart';
import '../../data/models/community.dart';
import 'community_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Post? _post;
  String? _error;
  final _comment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await context.read(communityRepoProvider).post(widget.id);
      if (mounted) setState(() => _post = p);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final restricted = ref.watch(sessionProvider).restricted;
    final meId = context.read(backendProvider).userId;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Post'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _post == null
              ? const LoadingPanel()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          PostCard(post: _post!, onChanged: _load),
                          const SizedBox(height: 6),
                          Text('Comments',
                              style: T.headline.copyWith(fontSize: 20)),
                          const SizedBox(height: 8),
                          if (_post!.comments.isEmpty)
                            Text('No comments yet. Write a kind comment.',
                                style: T.small),
                          for (final c in _post!.comments)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: C.surface,
                                border: Border.all(color: C.line),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Avatar(name: c.authorName, size: 30),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: InkWell(
                                          onTap: c.authorId == null
                                              ? null
                                              : () => context.go(
                                                  '/members/${c.authorId}'),
                                          child: Text(c.authorName ?? '',
                                              style: T.bodyStrong.copyWith(
                                                  fontSize: 13)),
                                        ),
                                      ),
                                      Text(
                                        Dates.timeAgo(
                                            DateTime.parse(c.createdAt)),
                                        style: T.small.copyWith(fontSize: 11),
                                      ),
                                      if (c.authorId == meId ||
                                          _post!.authorId == meId)
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 16,
                                              color: C.rust),
                                          onPressed: () async {
                                            try {
                                              await context
                                                  .read(communityRepoProvider)
                                                  .deleteComment(c.id);
                                              _load();
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            friendlyError(
                                                                e))));
                                              }
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(c.body,
                                      style: T.body.copyWith(fontSize: 14)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!restricted)
                      Container(
                        color: C.surface,
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 8,
                          top: 8,
                          bottom:
                              MediaQuery.of(context).viewInsets.bottom + 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _comment,
                                maxLength: 1000,
                                decoration: const InputDecoration(
                                  hintText: 'Write a kind comment',
                                  border: InputBorder.none,
                                  filled: false,
                                  counterText: '',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: C.royal),
                              onPressed: () async {
                                final body = _comment.text.trim();
                                if (body.isEmpty) return;
                                try {
                                  await context
                                      .read(communityRepoProvider)
                                      .addComment(widget.id, body);
                                  _comment.clear();
                                  _load();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content:
                                                Text(friendlyError(e))));
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
