import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/completion.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/completion_meter.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/panel.dart';
import '../../data/models/relationship.dart';
import '../../data/repositories/discovery_repo.dart';
import '../../data/repositories/relationships_repo.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  RecommendationsResult? _recs;
  String? _recsError;
  bool _loadingRecs = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadingRecs = true;
      _recsError = null;
    });
    try {
      final repo = context.read(discoveryRepoProvider);
      final recs = await repo.recommendations(lim: 3, off: 0);
      List<Map<String, dynamic>> consult = const [];
      try {
        consult = await context
            .read(backendProvider)
            .select('consultation_requests');
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _recs = recs;
        _loadingRecs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recsError = friendlyError(e);
        _loadingRecs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final me = session.me;
    if (me == null) return const LoadingPanel();
    final minCompletion =
        ref.watch(appSettingsProvider('profile.min_completion_for_discovery'))
                .valueOrNull as int? ??
            60;
    final weights = ref
        .watch(appSettingsProvider('profile.completion_weights'))
        .valueOrNull as Map?;
    final hasPrefs =
        ref.watch(hasPreferencesProvider).valueOrNull ?? false;

    final missing = missingSections(
      me,
      hasPreferences: hasPrefs,
      weights: weights
          ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await context.read(sessionProvider.notifier).reload();
        await _load();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome, ${me.preferredName ?? me.firstName}',
            style: T.display,
          ),
          const SizedBox(height: 14),
          Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CompletionMeter(me.completionPercent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your profile', style: T.headline.copyWith(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        me.completionPercent >= minCompletion
                            ? 'Your profile is complete enough to appear in '
                                "other members' recommendations."
                            : 'Recommendations depend on good profile '
                                'information. Reach $minCompletion% to appear '
                                'in recommended matches.',
                        style: T.body.copyWith(fontSize: 14),
                      ),
                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Still missing',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: C.muted)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final m in missing)
                              ActionChip(
                                label: Text(m.label,
                                    style: const TextStyle(fontSize: 12)),
                                onPressed: () => context.go(m.route),
                                backgroundColor: C.plum50,
                                side: const BorderSide(color: C.line),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _StatusPanel(),
          const SizedBox(height: 18),
          if (_loadingRecs)
            const SkeletonList(count: 2)
          else if (_recsError != null)
            ErrorView(message: _recsError!, onRetry: _load)
          else if (_recs != null && _recs!.gate.ok && _recs!.rows.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recommended matches', style: T.headline.copyWith(fontSize: 22)),
                TextButton(
                  onPressed: () => context.go('/discover'),
                  child: Text('See all recommendations',
                      style: T.bodyStrong.copyWith(color: C.royal, fontSize: 13)),
                ),
              ],
            ),
            for (final card in _recs!.rows) ...[
              MemberCard(
                data: card,
                onView: () => context.go('/members/${card.id}'),
                onOpenConversation: null,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusPanel extends ConsumerWidget {
  const _StatusPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).me;
    final summary = ref.watch(matchSummaryProvider).valueOrNull;
    final repo = RelationshipsRepository(ref.read(backendProvider));
    return FutureBuilder<RelationshipsResult>(
      future: repo.myRelationships(),
      builder: (ctx, relSnap) {
        final rel = relSnap.data;
        return Panel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              _row('Relationship status', maritalText(rel?.maritalStatus), () => context.go('/relationships')),
              _row(
                'Looking for',
                (me?.relationshipIntentions.isNotEmpty == true)
                    ? me!.relationshipIntentions.join(', ')
                    : 'Add your intention',
                () => context.go('/profile/edit'),
              ),
              _row(
                'Interest waiting for you',
                (summary?.interestsReceived ?? 0) > 0
                    ? '${summary!.interestsReceived}'
                    : 'None',
                () => context.go('/connections'),
              ),
              _row(
                'Matches',
                (summary?.matches ?? 0) > 0 ? '${summary!.matches}' : 'None yet',
                () => context.go('/connections?tab=matches'),
              ),
              if ((me?.maritalStatus ?? '') == 'married')
                _row('Household', 'View', () => context.go('/household')),
              _row('TRSH membership', me?.membershipStatus ?? 'Not verified', null),
              _row('Indawo Ephakeme', _consultationText(rel), null),
            ],
          ),
        );
      },
    );
  }

  String maritalText(String? s) {
    const labels = {
      'single': 'Single',
      'separated': 'Separated',
      'divorced': 'Divorced',
      'widowed': 'Widowed',
      'dating': 'Dating',
      'courtship': 'Courtship',
      'marriage_preparation': 'Marriage preparation',
      'married': 'Married',
    };
    return s == null ? 'Single' : (labels[s] ?? s);
  }

  String _consultationText(RelationshipsResult? rel) {
    final active = rel?.active ?? const <RelationshipState>[];
    if (active.isEmpty) return 'No consultation in progress';
    final st = active.first.consultationStatus;
    switch (st) {
      case 'awaiting_partner':
        return 'A request is waiting for your confirmation';
      case 'in_progress':
        return 'In progress with your consultant';
      case 'awaiting_assignment':
        return 'Waiting for a consultant';
      case 'awaiting_requester':
        return 'Waiting for your partner to confirm';
      default:
        return 'No consultation in progress';
    }
  }

  Widget _row(String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 14, color: C.muted)),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: C.ink),
                textAlign: TextAlign.end,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 18, color: C.muted),
          ],
        ),
      ),
    );
  }
}
