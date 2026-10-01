import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/panel.dart';
import '../../data/models/chat.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  List<ConversationSummary>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context.read(messagingRepoProvider).conversations();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  String _preview(ConversationSummary c) {
    if (c.lastBody == 'deleted') return 'Message deleted';
    switch (c.lastKind) {
      case 'image':
        return '${c.lastSenderId == context.read(backendProvider).userId ? 'You: ' : ''}Photo';
      case 'voice':
        return '${c.lastSenderId == context.read(backendProvider).userId ? 'You: ' : ''}Voice note';
      case 'video':
        return '${c.lastSenderId == context.read(backendProvider).userId ? 'You: ' : ''}Video';
      case 'system':
        return c.lastBody ?? '';
      default:
        final mine = c.lastSenderId == context.read(backendProvider).userId;
        return '${mine ? 'You: ' : ''}${c.lastBody ?? ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_rows == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [SkeletonList()],
      );
    }
    final open = _rows!.where((c) => !c.closed).toList();
    final ended = _rows!.where((c) => c.closed).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Talking Stage', style: T.headline.copyWith(fontSize: 24)),
            TextButton(
              onPressed: () => context.go('/relationships'),
              child: Text('My relationships',
                  style: T.bodyStrong.copyWith(color: C.royal, fontSize: 13)),
            ),
          ],
        ),
        if (open.isEmpty && ended.isEmpty)
          const EmptyState(
            message: 'No conversations yet. Matches open a private Talking '
                'Stage room for the two of you.',
            icon: Icons.chat_bubble_outline,
          ),
        for (final c in open) _row(c),
        if (ended.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Ended connections',
              style: T.bodyStrong.copyWith(color: C.muted, fontSize: 13)),
          const SizedBox(height: 6),
          for (final c in ended) _row(c),
        ],
      ],
    );
  }

  Widget _row(ConversationSummary c) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.go('/messages/${c.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.surface,
          border: Border.all(color: C.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Avatar(name: c.otherName, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.otherName,
                          style: T.bodyStrong.copyWith(fontSize: 15),
                        ),
                      ),
                      if (c.lastAt != null)
                        Text(
                          Dates.listStamp(DateTime.parse(c.lastAt!)),
                          style: T.small.copyWith(fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _preview(c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.small.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (c.unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: C.crimson,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${c.unread}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            if (c.closed)
              const Icon(Icons.lock_outline, size: 16, color: C.muted),
          ],
        ),
      ),
    );
  }
}
