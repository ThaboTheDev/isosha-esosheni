import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/panel.dart';
import '../../data/models/member.dart';
import '../../data/repositories/discovery_repo.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

const List<(String, String)> _tabs = [
  ('received', 'Interest received'),
  ('matches', 'Matches'),
  ('sent', 'Sent'),
  ('saved', 'Saved'),
  ('liked', 'Liked you'),
  ('hidden', 'Hidden'),
];

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  ConnectionsResult? _data;
  String? _error;
  String _tab = 'received';

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null &&
        _tabs.any((t) => t.$1 == widget.initialTab)) {
      _tab = widget.initialTab!;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read(discoveryRepoProvider).connections();
      if (mounted) setState(() => _data = res);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  int _count(String key) {
    if (_data == null) return 0;
    switch (key) {
      case 'received':
        return _data!.received.length;
      case 'matches':
        return _data!.matches.length;
      case 'sent':
        return _data!.sent.length;
      case 'saved':
        return _data!.saved.length;
      case 'liked':
        return _data!.likedMe.length;
      default:
        return _data!.hidden.length;
    }
  }

  List<MemberCardData> _rows(String key) {
    switch (key) {
      case 'received':
        return _data?.received ?? const [];
      case 'matches':
        return _data?.matches ?? const [];
      case 'sent':
        return _data?.sent ?? const [];
      case 'saved':
        return _data?.saved ?? const [];
      case 'liked':
        return _data?.likedMe ?? const [];
      default:
        return _data?.hidden ?? const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            children: [
              for (final t in _tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _tab = t.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _tab == t.$1 ? C.royal : C.surface,
                        border: Border.all(
                            color: _tab == t.$1 ? C.royal : C.line),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t.$2,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _tab == t.$1 ? Colors.white : C.plum700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _tab == t.$1
                                  ? Colors.white.withOpacity(0.2)
                                  : C.plum100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_count(t.$1)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _tab == t.$1 ? Colors.white : C.plum700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_tab == 'matches')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'A match means you both chose to talk. Each match has a '
              'private Talking Stage room, and your fuller profiles are '
              'visible to each other according to your privacy settings.',
              style: T.small.copyWith(fontSize: 12.5),
            ),
          ),
        Expanded(
          child: _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _data == null
                  ? const ListView(
                      padding: EdgeInsets.all(16),
                      children: [SkeletonList()],
                    )
                  : _body(),
        ),
      ],
    );
  }

  Widget _body() {
    final rows = _rows(_tab);
    if (rows.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyConnections(tab: _tab),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final card in rows) _row(card),
      ],
    );
  }

  Widget _row(MemberCardData card) {
    final repo = context.read(discoveryRepoProvider);
    switch (_tab) {
      case 'received':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MemberCard(
            data: card,
            variant: CardActionVariant.received,
            onAccept: () async {
              try {
                await repo.respondInterest(card.interestReceived!, true);
                _load();
              } catch (e) {
                _toast(e);
              }
            },
            onDecline: () async {
              try {
                await repo.respondInterest(card.interestReceived!, false);
                _load();
              } catch (e) {
                _toast(e);
              }
            },
            onView: () => context.go('/members/${card.id}'),
          ),
        );
      case 'matches':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MemberCard(
            data: card,
            variant: CardActionVariant.match,
            onOpenConversation: () => context.go('/messages/match/${card.id}'),
            onView: () => context.go('/members/${card.id}'),
            onEndMatch: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('End your match with ${card.displayName}?',
                      style: T.headline.copyWith(fontSize: 21)),
                  content: const Text(
                      'You can still find each other again later.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel')),
                    DangerConfirm(onConfirm: () => Navigator.of(ctx).pop(true)),
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await repo.endMatch(card.id);
                  _load();
                } catch (e) {
                  _toast(e);
                }
              }
            },
          ),
        );
      case 'sent':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MemberCard(
            data: card,
            variant: CardActionVariant.sent,
            onView: () => context.go('/members/${card.id}'),
            onWithdraw: () async {
              try {
                await repo.withdrawInterest(card.id);
                _load();
              } catch (e) {
                _toast(e);
              }
            },
          ),
        );
      case 'saved':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MemberCard(
            data: card,
            variant: CardActionVariant.saved,
            onView: () => context.go('/members/${card.id}'),
            onSave: () async {
              try {
                await repo.toggleSave(card.id);
                _load();
              } catch (e) {
                _toast(e);
              }
            },
          ),
        );
      case 'liked':
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MemberCard(
            data: card,
            onView: () => context.go('/members/${card.id}'),
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: MemberCard(
            data: card,
            onView: () => context.go('/members/${card.id}'),
            onPass: () async {
              try {
                await repo.setPass(card.id, false);
                _load();
              } catch (e) {
                _toast(e);
              }
            },
          ),
        );
    }
  }

  void _toast(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

class DangerConfirm extends StatelessWidget {
  const DangerConfirm({super.key, required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) =>
      DangerButton(label: 'End match', onPressed: onConfirm);
}

class EmptyConnections extends StatelessWidget {
  const EmptyConnections({super.key, required this.tab});
  final String tab;

  @override
  Widget build(BuildContext context) {
    final messages = {
      'received': 'No interest waiting for you right now.',
      'matches': 'No matches yet. A match begins when you both agree to talk.',
      'sent': 'You have not sent any interest yet.',
      'saved': 'Members you save will appear here.',
      'liked': 'When a member likes your profile, you will see it here.',
      'hidden': 'Members you pass on will appear here.',
    };
    return EmptyState(
      message: messages[tab] ?? 'Nothing here yet.',
      actionLabel: 'Go to Discover',
      onAction: () => context.go('/discover'),
    );
  }
}
