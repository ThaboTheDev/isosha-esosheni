import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/panel.dart';

/// Consultant dashboard (role-gated).
class ConsultDashboardScreen extends StatefulWidget {
  const ConsultDashboardScreen({super.key});

  @override
  State<ConsultDashboardScreen> createState() => _ConsultDashboardScreenState();
}

class _ConsultDashboardScreenState extends State<ConsultDashboardScreen> {
  Map<String, dynamic>? _dash;
  String? _error;
  bool _factorOk = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final backend = context.read(backendProvider);
    final factors = await backend.listMfaFactors();
    if (!factors.any((f) => f.verified)) {
      if (mounted) setState(() => _factorOk = false);
      return;
    }
    try {
      final d = await context.read(consultRepoProvider).dashboard();
      if (mounted) setState(() => _dash = d);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_factorOk) {
      return Scaffold(
        appBar: const BrandHeader(showMenu: false, title: 'Consultations'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 36, color: C.muted),
              const SizedBox(height: 10),
              const Text('Set up two-factor authentication first',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              QuietButton(
                label: 'Open security settings',
                onPressed: () => context.go('/account/security'),
              ),
            ],
          ),
        ),
      );
    }
    final d = _dash;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Consultations'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : d == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Panel(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('Waiting',
                              (d['stats']?['waiting'] ?? 0).toString()),
                          _stat('In progress',
                              (d['stats']?['in_progress'] ?? 0).toString()),
                          _stat('Approved 90d',
                              (d['stats']?['approved_90d'] ?? 0).toString()),
                          _stat('Decided 90d',
                              (d['stats']?['decided_90d'] ?? 0).toString()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (d['assigner'] == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuietButton(
                          label: 'Households for review',
                          onPressed: () => context.go('/consult/households'),
                        ),
                      ),
                    Text('Waiting queue',
                        style: T.headline.copyWith(fontSize: 20)),
                    const SizedBox(height: 8),
                    _caseList((d['queue'] as List? ?? [])
                        .whereType<Map>()
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList()),
                    const SizedBox(height: 12),
                    Text('My cases', style: T.headline.copyWith(fontSize: 20)),
                    const SizedBox(height: 8),
                    _caseList((d['mine'] as List? ?? [])
                        .whereType<Map>()
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList()),
                    const SizedBox(height: 12),
                    Text('Recent', style: T.headline.copyWith(fontSize: 20)),
                    const SizedBox(height: 8),
                    _caseList((d['recent'] as List? ?? [])
                        .whereType<Map>()
                        .map((e) => Map<String, dynamic>.from(e))
                        .toList()),
                  ],
                ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: T.display.copyWith(fontSize: 24, color: C.plum700)),
        Text(label, style: T.small.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _caseList(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return Text('Nothing here.', style: T.small);
    }
    return Column(
      children: [
        for (final r in rows)
          InkWell(
            onTap: () => context.go('/consult/${r['id']}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.surface,
                border: Border.all(color: C.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (r['couple'] as String?) ??
                              (r['title'] as String?) ??
                              'Case',
                          style: T.bodyStrong.copyWith(fontSize: 14),
                        ),
                        Text((r['status'] as String?) ?? '',
                            style: T.small.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: C.muted, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Case detail: couple profile + timeline + sessions + notes. Never the
/// couple's messages.
class ConsultCaseScreen extends StatefulWidget {
  const ConsultCaseScreen({super.key, required this.id});

  final String id;

  @override
  State<ConsultCaseScreen> createState() => _ConsultCaseScreenState();
}

class _ConsultCaseScreenState extends State<ConsultCaseScreen> {
  Map<String, dynamic>? _case;
  String? _error;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await context.read(consultRepoProvider).consultation(widget.id);
      if (mounted) setState(() => _case = c);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _case;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Case'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : c == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      (c['couple'] as String?) ?? 'Consultation case',
                      style: T.headline.copyWith(fontSize: 22),
                    ),
                    Text('Status: ${c['status']}', style: T.small),
                    const SizedBox(height: 10),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sessions',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          for (final s in (c['sessions'] as List? ?? []))
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${Dates.fmt(DateTime.parse((s['at'] as String?) ?? DateTime.now().toIso8601String()))} · ${s['mode']} · ${s['status']}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _updateSession(Map<String, dynamic>.from(s)),
                                    child: const Text('Update',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          QuietButton(
                            label: 'Schedule session',
                            onPressed: _schedule,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Confidential notes (append-only, '
                              'never shown to the couple)',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          for (final n in (c['notes'] as List? ?? []))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                (n as Map)['body']?.toString() ?? '',
                                style: T.body.copyWith(fontSize: 13.5),
                              ),
                            ),
                          TextField(
                            controller: _note,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                hintText: 'Add a note', filled: true),
                          ),
                          const SizedBox(height: 8),
                          QuietButton(
                            label: 'Add note',
                            onPressed: () async {
                              if (_note.text.trim().isEmpty) return;
                              try {
                                await context
                                    .read(consultRepoProvider)
                                    .addNote(widget.id, _note.text.trim());
                                _note.clear();
                                _load();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(friendlyError(e))));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Outcome',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            'Requires at least one held session.',
                            style: T.small.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final r in [
                                ('approved', 'Approved'),
                                ('not_yet_ready', 'More time advised'),
                                ('not_approved', 'Not approved'),
                              ])
                                QuietButton(
                                  label: r.$2,
                                  onPressed: () => _outcome(r.$1),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _schedule() async {
    DateTime at = DateTime.now().add(const Duration(days: 1));
    String mode = 'in_person';
    final location = TextEditingController(text: 'Indawo Ephakeme room');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Schedule a session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: at,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setS(() => at = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(filled: true),
                  child: Text('${at.day}/${at.month}/${at.year}'),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: mode,
                items: const [
                  DropdownMenuItem(value: 'in_person', child: Text('In person')),
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'phone', child: Text('Phone')),
                ],
                onChanged: (v) => setS(() => mode = v ?? 'in_person'),
                decoration: const InputDecoration(labelText: 'Mode', filled: true),
              ),
              TextField(
                controller: location,
                decoration:
                    const InputDecoration(labelText: 'Location', filled: true),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            PrimaryButton(
                label: 'Schedule', onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await context.read(consultRepoProvider).scheduleSession(
            widget.id,
            at: at.toIso8601String(),
            minutes: 60,
            mode: mode,
            location: location.text.trim(),
          );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _updateSession(Map<String, dynamic> s) async {
    String st = (s['status'] as String?) ?? 'scheduled';
    final summary = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Update session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: st,
                items: const [
                  DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                  DropdownMenuItem(value: 'held', child: Text('Held')),
                  DropdownMenuItem(
                      value: 'cancelled', child: Text('Cancelled')),
                  DropdownMenuItem(value: 'missed', child: Text('Missed')),
                ],
                onChanged: (v) => setS(() => st = v ?? 'scheduled'),
                decoration:
                    const InputDecoration(labelText: 'Status', filled: true),
              ),
              TextField(
                controller: summary,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Summary (held sessions)', filled: true),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            PrimaryButton(
                label: 'Save', onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await context.read(consultRepoProvider).updateSession(
            (s['id'] as String?) ?? '',
            st: st,
            summary: summary.text.trim().isEmpty ? null : summary.text.trim(),
          );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _outcome(String result) async {
    final summary = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record outcome'),
        content: TextField(
          controller: summary,
          maxLines: 3,
          decoration: const InputDecoration(
              labelText: 'Shared summary for the couple', filled: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          PrimaryButton(
              label: 'Record', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context
          .read(consultRepoProvider)
          .recordOutcome(widget.id, result, summary.text.trim());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}

/// Households for Super Consultant review.
class ConsultHouseholdsScreen extends StatefulWidget {
  const ConsultHouseholdsScreen({super.key});

  @override
  State<ConsultHouseholdsScreen> createState() =>
      _ConsultHouseholdsScreenState();
}

class _ConsultHouseholdsScreenState extends State<ConsultHouseholdsScreen> {
  List<Map<String, dynamic>>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows =
          await context.read(consultRepoProvider).householdsForReview();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(
          showMenu: false, title: 'Households for review'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _rows == null
              ? const LoadingPanel()
              : _rows!.isEmpty
                  ? const EmptyState(
                      message: 'No households waiting for review.',
                      icon: Icons.home_outlined)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final h in _rows!)
                          Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (h['head_name'] as String?) ?? 'Household',
                                  style: T.headline.copyWith(fontSize: 19),
                                ),
                                Text((h['about'] as String?) ?? '',
                                    style: T.body.copyWith(fontSize: 13.5)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    PrimaryButton(
                                      label: 'Approve',
                                      onPressed: () => _review(h, true),
                                    ),
                                    DangerButton(
                                      label: 'Return',
                                      onPressed: () => _review(h, false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }

  Future<void> _review(Map<String, dynamic> h, bool approve) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve household' : 'Return household'),
        content: TextField(
          controller: note,
          maxLines: 2,
          decoration:
              const InputDecoration(labelText: 'Note', filled: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          PrimaryButton(
              label: 'Confirm', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context
          .read(consultRepoProvider)
          .reviewHousehold((h['id'] as String?) ?? '', approve, note.text.trim());
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}
