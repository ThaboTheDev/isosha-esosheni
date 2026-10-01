import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/panel.dart';
import '../../core/widgets/stage_dots.dart';
import '../../data/repositories/relationships_repo.dart';
import 'cards.dart';

class RelationshipsScreen extends StatefulWidget {
  const RelationshipsScreen({super.key});

  @override
  State<RelationshipsScreen> createState() => _RelationshipsScreenState();
}

class _RelationshipsScreenState extends State<RelationshipsScreen> {
  RelationshipsResult? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context.read(relationshipsRepoProvider).myRelationships();
      if (mounted) setState(() => _data = res);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    const labels = {
      'single': 'Single',
      'separated': 'Separated',
      'divorced': 'Divorced',
      'widowed': 'Widowed',
      'married': 'Married',
    };
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'My relationships'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _data == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Your status: ${labels[_data!.maritalStatus] ?? _data!.maritalStatus ?? 'Single'}. '
                      'Each step forward is agreed by both of you.',
                      style: T.small,
                    ),
                    const SizedBox(height: 12),
                    if (_data!.active.isEmpty)
                      const EmptyState(
                        message: 'No relationships right now. Matches from '
                            'Discover begin a Talking Stage.',
                      ),
                    for (final rel in _data!.active)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Avatar(name: rel.partnerName, size: 44),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      rel.partnerName ?? 'Member',
                                      style: T.headline.copyWith(fontSize: 20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: StageDots(rel.stage, ended: rel.ended),
                              ),
                              const SizedBox(height: 12),
                              RelationshipCard(
                                state: rel,
                                myId: context.read(backendProvider).userId,
                                onChanged: _load,
                              ),
                              const SizedBox(height: 10),
                              ConsultationCard(
                                relationshipId: rel.id,
                                onChanged: _load,
                              ),
                              if (rel.householdNote != null) ...[
                                const SizedBox(height: 10),
                                HouseholdNote(text: rel.householdNote!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (_data!.past.isNotEmpty) ...[
                      Text('Past relationships',
                          style: T.bodyStrong.copyWith(color: C.muted)),
                      const SizedBox(height: 8),
                      for (final rel in _data!.past)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Panel(
                            child: Row(
                              children: [
                                Avatar(name: rel.partnerName, size: 36),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(rel.partnerName ?? '',
                                      style: T.bodyStrong.copyWith(
                                          fontSize: 14)),
                                ),
                                Text('Ended',
                                    style: T.small.copyWith(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
    );
  }
}

/// Resolves /messages/match/:matchId to a conversation then replaces.
class MatchRedirectScreen extends StatelessWidget {
  const MatchRedirectScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConversationSummaryLike>>(
      future: context.read(messagingRepoProvider).conversations().then(
          (rows) => rows
              .where((c) => c.otherId == matchId)
              .map((c) => ConversationSummaryLike(c.id))
              .toList()),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.done) {
          final conv = snap.data?.firstOrNull;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (conv != null) {
              context.go('/messages/${conv.id}');
            } else {
              context.go('/messages');
            }
          });
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class ConversationSummaryLike {
  const ConversationSummaryLike(this.id);
  final String id;
}
