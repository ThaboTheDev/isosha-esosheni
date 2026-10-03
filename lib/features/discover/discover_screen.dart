import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../data/repositories/discovery_repo.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gate_notice.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/member_card.dart';
import '../../core/widgets/panel.dart';
import '../../data/models/member.dart';

const List<String> provinces = [
  'Eastern Cape',
  'Free State',
  'Gauteng',
  'KwaZulu-Natal',
  'Limpopo',
  'Mpumalanga',
  'North West',
  'Northern Cape',
  'Western Cape',
];

const List<String> saLanguages = [
  'isiZulu',
  'isiXhosa',
  'Sesotho',
  'Setswana',
  'Sepedi',
  'English',
  'Afrikaans',
  'Xitsonga',
  'siSwati',
  'Tshivenda',
  'isiNdebele',
];

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _tab = 0;
  bool _householdsEligible = false;

  @override
  void initState() {
    super.initState();
    _checkHouseholds();
  }

  Future<void> _checkHouseholds() async {
    // The web shows the Households tab for unmarried members open to a
    // polygamous family; the backend decides via household_directory().
    try {
      final me = context.read(sessionProvider).me;
      final open = (me?.relationshipIntentions ?? [])
              .contains('open_to_polygamous_marriage') ||
          (me?.relationshipIntentions ?? []).contains('traditional_family');
      if (!open) return;
      final dir = await context.read(householdsRepoProvider).directory();
      if (mounted) setState(() => _householdsEligible = dir.isNotEmpty || open);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _tabPill(0, 'Recommended for you'),
                _tabPill(1, 'Search'),
                if (_householdsEligible) _tabPill(2, 'Households'),
              ],
            ),
          ),
        ),
        Expanded(
          child: _tab == 0
              ? const _RecommendedTab()
              : _tab == 1
                  ? const _SearchTab()
                  : const _HouseholdsTab(),
        ),
      ],
    );
  }

  Widget _tabPill(int i, String label) {
    final selected = _tab == i;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? C.royal : C.surface,
            border: Border.all(color: selected ? C.royal : C.line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : C.plum700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared "send interest" dialog with the optional note.
Future<void> showSendInterestDialog(
  BuildContext context,
  MemberCardData member,
  Future<void> Function(String? note) send,
) async {
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Send interest to ${member.displayName}',
          style: T.headline.copyWith(fontSize: 21)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: note,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'Add a short, respectful note (optional).',
              filled: true,
            ),
          ),
          const Text(
            'Keep contact details for later, once you are matched.',
            style: TextStyle(fontSize: 12, color: C.muted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        GoldButton(
          label: 'Send interest',
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  if (ok == true) await send(note.text.trim().isEmpty ? null : note.text.trim());
}

class _RecommendedTab extends StatefulWidget {
  const _RecommendedTab();

  @override
  State<_RecommendedTab> createState() => _RecommendedTabState();
}

class _RecommendedTabState extends State<_RecommendedTab> {
  RecommendationsResult? _result;
  String? _error;
  bool _loading = true;
  bool _moreAvailable = true;

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
      final res = await context
          .read(discoveryRepoProvider)
          .recommendations(lim: 12, off: 0);
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
        _moreAvailable = res.rows.length > 12;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _more() async {
    if (_result == null) return;
    try {
      final res = await context
          .read(discoveryRepoProvider)
          .recommendations(lim: 13, off: _result!.rows.length);
      if (!mounted) return;
      setState(() {
        _result = RecommendationsResult(
          gate: res.gate,
          rows: [..._result!.rows, ...res.rows.take(12)],
          disclaimer: res.disclaimer,
        );
        _moreAvailable = res.rows.length > 12;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [SkeletonList(count: 3)],
      );
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    final res = _result!;
    final rows = res.rows.take(12 * 10).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GateNotice(
          gate: res.gate,
          onSeeMissing: () => context.go('/profile/edit'),
        ),
        if (res.disclaimer != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${res.disclaimer}\nScores use only the information members '
              'have provided.',
              style: T.small.copyWith(fontSize: 12.5),
            ),
          ),
        if (rows.isEmpty)
          const EmptyState(
            message: 'No recommendations right now. Completing your profile '
                'and partner preferences helps, and you can also search '
                'directly.',
          ),
        for (final card in rows)
          _DiscoverCard(data: card, onChanged: _load),
        if (_moreAvailable)
          Center(
            child: QuietButton(label: 'More recommendations', onPressed: _more),
          ),
      ],
    );
  }
}

class _DiscoverCard extends ConsumerWidget {
  const _DiscoverCard({required this.data, required this.onChanged});

  final MemberCardData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarUrlProvider(data.avatarPath)).valueOrNull;
    final repo = context.read(discoveryRepoProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MemberCard(
        data: data,
        avatarUrl: avatar,
        variant: CardActionVariant.discover,
        onView: () => context.go('/members/${data.id}'),
        onSendInterest: () async {
          await showSendInterestDialog(context, data, (note) async {
            try {
              await repo.sendInterest(data.id, note: note);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Interest sent.')));
                onChanged();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(friendlyError(e))));
              }
            }
          });
        },
        onLike: () async {
          try {
            await repo.toggleLike(data.id);
            onChanged();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(friendlyError(e))));
            }
          }
        },
        onSave: () async {
          try {
            await repo.toggleSave(data.id);
            onChanged();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(friendlyError(e))));
            }
          }
        },
        onPass: () async {
          try {
            await repo.setPass(data.id, true);
            onChanged();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(friendlyError(e))));
            }
          }
        },
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final Map<String, dynamic> _filters = {};
  SearchResult? _result;
  String? _error;
  bool _loading = false;

  Future<void> _search({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context
          .read(discoveryRepoProvider)
          .search(_filters, page: page);
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_result != null) GateNotice(gate: _result!.gate),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Search members',
                icon: Icons.search,
                onPressed: () => _search(),
              ),
            ),
            const SizedBox(width: 8),
            QuietButton(
              label: 'Filters',
              icon: Icons.tune,
              onPressed: () async {
                await _showFilters();
                if (mounted) _search();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const SkeletonList(count: 3)
        else if (_error != null)
          ErrorView(message: _error!, onRetry: () => _search())
        else if (_result != null) ...[
          Text('${_result!.total} members found', style: T.bodyStrong),
          const SizedBox(height: 10),
          for (final card in _result!.rows)
            _DiscoverCard(data: card, onChanged: () => _search()),
          if (_result!.rows.length < _result!.total)
            Center(
              child: QuietButton(
                label: 'More results',
                onPressed: () => _search(
                    page: (_result!.rows.length ~/ _result!.pageSize) + 1),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Results include only members your preferences and theirs '
            'allow, and only match a filter where that member has chosen '
            'to show the detail.',
            style: T.small.copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        initial: _filters,
        onApply: (f) => _filters
          ..clear()
          ..addAll(f),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.onApply});

  final Map<String, dynamic> initial;
  final ValueChanged<Map<String, dynamic>> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Map<String, dynamic> _f = Map.of(widget.initial);
  late int _minAge = (_f['age_min'] as int?) ?? 18;
  late int _maxAge = (_f['age_max'] as int?) ?? 99;
  late String? _province = _f['province'] as String?;
  late final _city = TextEditingController(text: _f['city'] as String? ?? '');
  late String? _lookingFor = _f['looking_for'] as String?;
  late final _profession =
      TextEditingController(text: _f['profession'] as String? ?? '');
  late String? _education = _f['education'] as String?;
  late String? _language = _f['language'] as String?;
  late String? _wantsChildren = _f['wants_children'] as String?;
  late String? _hasChildren = _f['has_children'] as String?;
  late String? _status = _f['relationship_status'] as String?;
  late List<String> _tags = List<String>.from(_f['tags'] as List? ?? const []);

  @override
  void dispose() {
    _city.dispose();
    _profession.dispose();
    super.dispose();
  }

  void _apply() {
    final out = <String, dynamic>{};
    if (_minAge != 18) out['age_min'] = _minAge;
    if (_maxAge != 99) out['age_max'] = _maxAge;
    if (_province != null) out['province'] = _province;
    if (_city.text.trim().isNotEmpty) out['city'] = _city.text.trim();
    if (_lookingFor != null) out['looking_for'] = _lookingFor;
    if (_profession.text.trim().isNotEmpty) {
      out['profession'] = _profession.text.trim();
    }
    if (_education != null) out['education'] = _education;
    if (_language != null) out['language'] = _language;
    if (_wantsChildren != null) out['wants_children'] = _wantsChildren;
    if (_hasChildren != null) out['has_children'] = _hasChildren;
    if (_status != null) out['relationship_status'] = _status;
    if (_tags.isNotEmpty) out['tags'] = _tags;
    widget.onApply(out);
    Navigator.of(context).pop();
  }

  Widget _drop<T>(String label, T? value, List<T> values,
      ValueChanged<T?> onSet, String Function(T) labelOf) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: [
          const DropdownMenuItem(value: null, child: Text('Any')),
          for (final v in values)
            DropdownMenuItem(value: v, child: Text(labelOf(v))),
        ],
        onChanged: onSet,
        decoration: InputDecoration(labelText: label, filled: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search filters', style: T.headline),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Age from $_minAge to $_maxAge',
                            style: T.bodyStrong.copyWith(fontSize: 14)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          min: 18,
                          max: 120,
                          value: _minAge.toDouble(),
                          onChanged: (v) => setState(() {
                            _minAge = v.round();
                            if (_maxAge < _minAge) _maxAge = _minAge;
                          }),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          min: 18,
                          max: 120,
                          value: _maxAge.toDouble(),
                          onChanged: (v) => setState(() {
                            _maxAge = v.round();
                            if (_maxAge < _minAge) _minAge = _maxAge;
                          }),
                        ),
                      ),
                    ],
                  ),
                  _drop('Province', _province, provinces,
                      (v) => setState(() => _province = v), (v) => v),
                  TextField(
                    controller: _city,
                    decoration: const InputDecoration(
                        labelText: 'City or town', filled: true),
                  ),
                  const SizedBox(height: 10),
                  _drop('Looking for', _lookingFor,
                      intentionLabels.values.toList(),
                      (v) => setState(() => _lookingFor = v), (v) => v),
                  TextField(
                    controller: _profession,
                    decoration: const InputDecoration(
                        labelText: 'Profession', filled: true),
                  ),
                  const SizedBox(height: 10),
                  _drop('Education', _education,
                      [
                        'Primary school',
                        'High school / Matric',
                        'Certificate',
                        'Diploma',
                        "Bachelor's degree",
                        'Honours',
                        "Master's degree",
                        'Doctorate',
                        'Trade qualification',
                      ],
                      (v) => setState(() => _education = v), (v) => v),
                  _drop('Language', _language, saLanguages,
                      (v) => setState(() => _language = v), (v) => v),
                  _drop('Wants children', _wantsChildren,
                      ['yes', 'no', 'open', 'unsure'],
                      (v) => setState(() => _wantsChildren = v), (v) => v),
                  _drop('Has children', _hasChildren, ['yes', 'no'],
                      (v) => setState(() => _hasChildren = v), (v) => v),
                  _drop('Relationship status', _status,
                      [
                        'single',
                        'divorced',
                        'widowed',
                        'separated',
                        'dating',
                        'courtship',
                      ],
                      (v) => setState(() => _status = v),
                      (v) => maritalLabel(v)),
                  const SizedBox(height: 4),
                  Text('Interest, value or lifestyle',
                      style: T.bodyStrong.copyWith(fontSize: 14)),
                  TagInput(tags: _tags, onChanged: (t) => setState(() => _tags = t)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              QuietButton(label: 'Clear', onPressed: () {
                widget.onApply({});
                Navigator.of(context).pop();
              }),
              const SizedBox(width: 8),
              PrimaryButton(label: 'Apply', onPressed: _apply),
            ],
          ),
        ],
      ),
    );
  }
}

class _HouseholdsTab extends StatefulWidget {
  const _HouseholdsTab();

  @override
  State<_HouseholdsTab> createState() => _HouseholdsTabState();
}

class _HouseholdsTabState extends State<_HouseholdsTab> {
  List<MemberCardData>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context.read(householdsRepoProvider).directory();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_rows!.isEmpty)
          const EmptyState(
            message: 'No households are seeking at the moment.',
          ),
        for (final h in _rows!)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: MemberCard(
              data: h,
              variant: CardActionVariant.discover,
              onSendInterest: () async {
                final repo = context.read(householdsRepoProvider);
                await showSendInterestDialog(context, h, (note) async {
                  try {
                    await repo.sendInterest(h.id, note: note);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Interest sent.')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyError(e))));
                    }
                  }
                });
              },
              onView: () => context.go('/members/${h.id}'),
            ),
          ),
      ],
    );
  }
}
