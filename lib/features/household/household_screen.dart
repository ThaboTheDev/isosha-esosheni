import 'package:flutter/material.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/panel.dart';
import '../../data/repositories/households_repo.dart';
import '../discover/discover_screen.dart' show provinces;

const Map<String, String> householdStatusLabels = {
  'draft': 'Draft, not yet submitted',
  'awaiting_consent': "Waiting for every wife's consent",
  'awaiting_review': 'Waiting for Super Consultant review',
  'active': 'Active and visible to members open to it',
  'consent_withdrawn': 'On hold: a wife withdrew consent',
  'returned': 'Returned for changes',
  'completed': 'Completed: a marriage was recorded',
  'closed': 'Closed',
};

const Map<String, String> consentLabels = {
  'pending': 'Not yet answered',
  'given': 'Consent given',
  'declined': 'Did not consent',
  'withdrawn': 'Consent withdrawn',
};

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  HouseholdResult? _data;
  String? _error;

  final _about = TextEditingController();
  final _seeking = TextEditingController();
  final _city = TextEditingController();
  String _province = provinces.first;
  int _children = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _about.dispose();
    _seeking.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await context.read(householdsRepoProvider).myHousehold();
      if (!mounted) return;
      setState(() {
        _data = res;
        final hh = res.household;
        if (hh != null) {
          _about.text = (hh['about'] as String?) ?? '';
          _seeking.text = (hh['seeking'] as String?) ?? '';
          _city.text = (hh['city'] as String?) ?? '';
          _province = (hh['province'] as String?) ?? provinces.first;
          _children = (hh['children'] as num?)?.toInt() ?? 0;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Household'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _data == null
              ? const LoadingPanel()
              : _body(),
    );
  }

  Widget _body() {
    final d = _data!;
    if (d.household == null && !d.eligibility['eligible'].isTrue) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(
            message: d.eligibility['reason'] == 'not_married'
                ? 'The household area is for married members. Your journey '
                    'toward marriage continues in My relationships.'
                : 'Your household is not open at the moment.',
          ),
        ],
      );
    }
    final hh = d.household ?? const <String, dynamic>{};
    final status = (hh['status'] as String?) ?? 'draft';
    final wives = (hh['wives'] as List? ?? d.wivesOnRecord)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final relationships = (hh['relationships'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final meIsWife = !d.asHead;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Status'),
              const SizedBox(height: 6),
              Text(
                householdStatusLabels[status] ?? status,
                style: T.headline.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              if (d.asHead) ...[
                AppField(
                  label: 'About your household',
                  child: TextField(
                    controller: _about,
                    maxLines: 3,
                    decoration: const InputDecoration(filled: true),
                  ),
                ),
                const SizedBox(height: 10),
                AppField(
                  label: 'What you are seeking',
                  child: TextField(
                    controller: _seeking,
                    maxLines: 3,
                    decoration: const InputDecoration(filled: true),
                  ),
                ),
                const SizedBox(height: 10),
                AppField(
                  label: 'Children in the home',
                  child: Stepper2(
                    value: _children,
                    onChanged: (v) => setState(() => _children = v),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _province,
                  items: [
                    for (final p in provinces)
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) => setState(() => _province = v!),
                  decoration: const InputDecoration(
                      labelText: 'Province', filled: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _city,
                  decoration:
                      const InputDecoration(labelText: 'City', filled: true),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    PrimaryButton(
                      label: 'Save draft',
                      onPressed: () => _save(submit: false),
                    ),
                    if (status == 'draft' || status == 'returned')
                      GoldButton(
                        label: 'Submit for consent',
                        onPressed: () => _save(submit: true),
                      ),
                    if (status == 'active')
                      DangerButton(
                        label: 'Close household',
                        onPressed: () async {
                          final reason = TextEditingController();
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c2) => AlertDialog(
                              title: const Text('Close this household?'),
                              content: TextField(
                                controller: reason,
                                decoration: const InputDecoration(
                                    labelText: 'Reason', filled: true),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(c2).pop(false),
                                    child: const Text('Cancel')),
                                DangerButton(
                                    label: 'Close',
                                    onPressed: () =>
                                        Navigator.of(c2).pop(true)),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await context
                                .read(householdsRepoProvider)
                                .closeHousehold((hh['id'] as String?) ?? '',
                                    reason: reason.text.trim());
                            _load();
                          } catch (e) {
                            _toast(e);
                          }
                        },
                      ),
                  ],
                ),
              ] else if (meIsWife && status == 'awaiting_consent') ...[
                const Text(
                  'Your head of household has submitted the household for '
                  'seeking. Your consent is required.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    PrimaryButton(
                      label: 'Give consent',
                      onPressed: () => _consent(true),
                    ),
                    QuietButton(
                      label: 'Do not consent',
                      onPressed: () => _consent(false),
                    ),
                  ],
                ),
              ] else if (meIsWife) ...[
                QuietButton(
                  label: 'Withdraw consent',
                  onPressed: () => _withdraw(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (wives.isNotEmpty) ...[
          Text('Spouses', style: T.headline.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          for (final w in wives)
            Panel(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (w['display_name'] as String?) ??
                          (w['name'] as String?) ??
                          'Wife',
                      style: T.bodyStrong.copyWith(fontSize: 14),
                    ),
                  ),
                  Text(
                    consentLabels[(w['consent'] as String?) ?? 'pending'] ??
                        'Not yet answered',
                    style: const TextStyle(fontSize: 12.5, color: C.muted),
                  ),
                ],
              ),
            ),
        ],
        if (relationships.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Household relationships',
              style: T.headline.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'Names and stages only. Messages are never visible here.',
            style: T.small.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          for (final r in relationships)
            Panel(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text((r['display_name'] as String?) ?? '',
                        style: T.bodyStrong.copyWith(fontSize: 14)),
                  ),
                  Text((r['stage'] as String?) ?? '',
                      style: const TextStyle(fontSize: 12.5, color: C.muted)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _save({required bool submit}) async {
    try {
      final repo = context.read(householdsRepoProvider);
      await repo.saveHousehold(
        about: _about.text.trim(),
        seeking: _seeking.text.trim(),
        children: _children,
        province: _province,
        city: _city.text.trim(),
      );
      if (submit) await repo.submitHousehold();
      _load();
    } catch (e) {
      _toast(e);
    }
  }

  Future<void> _consent(bool give) async {
    try {
      await context.read(householdsRepoProvider).respondHouseholdConsent(
          (_data!.household?['id'] as String?) ?? '', give);
      _load();
    } catch (e) {
      _toast(e);
    }
  }

  Future<void> _withdraw() async {
    try {
      await context.read(householdsRepoProvider).withdrawConsent(
          (_data!.household?['id'] as String?) ?? '');
      _load();
    } catch (e) {
      _toast(e);
    }
  }

  void _toast(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

extension on dynamic {
  bool get isTrue => this == true;
}

class Stepper2 extends StatelessWidget {
  const Stepper2({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Text('$value', style: T.bodyStrong),
        IconButton(
          onPressed: value < 30 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
