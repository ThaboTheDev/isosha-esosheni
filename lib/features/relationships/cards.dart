import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gate_notice.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/panel.dart';
import '../../core/widgets/stage_dots.dart';
import '../../data/models/relationship.dart';

const Map<String, String> stageGuidance = {
  'dating': 'Dating is a committed step. Both your profiles will show '
      'Dating, and neither of you can begin dating anyone else.',
  'courtship': 'Courtship is a serious, declared relationship with marriage '
      'in view.',
  'marriage_preparation': 'In marriage preparation you are engaged and no '
      'longer appear in discovery.',
  'married': 'Record your marriage once it has taken place. A Relationship '
      'Administrator verifies it before your status becomes Married.',
};

/// The RelationshipCard: stage progress, next step and the governed
/// actions. The server decides everything; this renders `state.gate`.
class RelationshipCard extends StatefulWidget {
  const RelationshipCard({
    super.key,
    required this.state,
    required this.onChanged,
    this.myId,
  });

  final RelationshipState state;
  final VoidCallback onChanged;
  final String? myId;

  @override
  State<RelationshipCard> createState() => _RelationshipCardState();
}

class _RelationshipCardState extends State<RelationshipCard> {
  bool _busy = false;

  String get _nextLine {
    final s = widget.state;
    if (s.paused) return 'Paused';
    if (s.gate.proposalWaiting) return 'Waiting for your answer';
    if (s.gate.ok) {
      return 'Ready for ${s.gate.targetLabel ?? 'the next step'} when you '
          'both are';
    }
    final reasons = s.gate.reasons;
    if (reasons.contains('consultation_needed')) {
      return 'Indawo Ephakeme consultation comes before '
          '${s.gate.targetLabel ?? 'the next step'}';
    }
    if (reasons.contains('consultation_open')) return 'Consultation in progress';
    if (reasons.contains('marriage_pending')) {
      return 'Marriage waiting to be recorded';
    }
    if (reasons.contains('exclusive')) {
      return 'One of you is in another relationship at this stage';
    }
    return '';
  }

  Future<void> _propose() async {
    final target = widget.state.gate.target;
    final isMarriage = target == 'married';
    final note = TextEditingController();
    DateTime? marriageDate;
    String? marriageType;
    final details = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(
            'Propose ${widget.state.gate.targetLabel ?? 'next step'}?',
            style: T.headline.copyWith(fontSize: 21),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stageGuidance[target] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(stageGuidance[target]!,
                        style: T.small.copyWith(fontSize: 13)),
                  ),
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'A note for your partner (optional)',
                      filled: true),
                ),
                if (isMarriage) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setS(() => marriageDate = d);
                    },
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(labelText: 'Marriage date', filled: true),
                      child: Text(marriageDate == null
                          ? 'Choose'
                          : Dates.fmtDate(marriageDate!)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: marriageType,
                    items: [
                      for (final e in marriageTypes.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) => setS(() => marriageType = v),
                    decoration:
                        const InputDecoration(labelText: 'Marriage type', filled: true),
                  ),
                  TextField(
                    controller: details,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Marriage details', filled: true),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            GoldButton(
                label: 'Propose',
                onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (isMarriage && (marriageDate == null || marriageType == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marriage date and type are required.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read(relationshipsRepoProvider).proposeStage(
            widget.state.id,
            note: note.text.trim(),
            marriageDate:
                marriageDate == null ? null : Dates.dateInput(marriageDate!),
            marriageType: marriageType,
            marriageDetails: details.text.trim(),
          );
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _respond(bool accept) async {
    final prop = widget.state.proposal;
    if (prop == null) return;
    setState(() => _busy = true);
    try {
      await context
          .read(relationshipsRepoProvider)
          .respondProposal(prop.id, accept,
              note: accept ? null : 'Not yet');
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pause() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pause this relationship?',
            style: T.headline.copyWith(fontSize: 21)),
        content: TextField(
          controller: reason,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Reason (shared with your partner)', filled: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          QuietButton(
              label: 'Pause', onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context
          .read(relationshipsRepoProvider)
          .pause(widget.state.id, reason: reason.text.trim());
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final iAmProposer = s.proposal?.fromId != null &&
        s.proposal!.fromId == widget.myId;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your journey', style: T.headline.copyWith(fontSize: 20)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: StageDots(s.stage, ended: s.ended),
          ),
          const SizedBox(height: 10),
          if (s.paused)
            const Text('Paused', style: TextStyle(color: C.muted, fontSize: 14))
          else if (s.gate.proposalWaiting && !iAmProposer) ...[
            Text(
              '${'Your partner'} proposes ${stageLabels[s.proposal?.targetStage ?? ''] ?? s.proposal?.targetStage}. '
              'Waiting for your answer.',
              style: const TextStyle(fontSize: 14, color: C.ink),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PrimaryButton(
                    label: 'Accept', busy: _busy, onPressed: () => _respond(true)),
                const SizedBox(width: 8),
                QuietButton(
                    label: 'Not yet', busy: _busy, onPressed: () => _respond(false)),
              ],
            ),
          ] else if (s.gate.proposalWaiting && iAmProposer) ...[
            Text('Waiting for your partner\'s answer.',
                style: T.small.copyWith(fontSize: 13)),
            const SizedBox(height: 8),
            QuietButton(
              label: 'Withdraw proposal',
              busy: _busy,
              onPressed: () async {
                try {
                  await context
                      .read(relationshipsRepoProvider)
                      .withdrawProposal(s.proposal!.id);
                  widget.onChanged();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(friendlyError(e))));
                  }
                }
              },
            ),
          ] else if (_nextLine.isNotEmpty) ...[
            Text(_nextLine, style: const TextStyle(fontSize: 14, color: C.ink)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (s.gate.ok && !s.paused)
                GoldButton(
                  label: 'Propose ${s.gate.targetLabel ?? 'next step'}',
                  busy: _busy,
                  onPressed: _propose,
                ),
              if (!s.paused && s.stage != 'married' && !s.ended)
                QuietButton(label: 'Pause', onPressed: _pause),
              if (s.paused)
                PrimaryButton(
                  label: 'Resume',
                  onPressed: () async {
                    try {
                      await context
                          .read(relationshipsRepoProvider)
                          .resume(s.id);
                      widget.onChanged();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyError(e))));
                      }
                    }
                  },
                ),
            ],
          ),
          if (s.householdOnHold) ...[
            const SizedBox(height: 10),
            BronzeInfoPanel(
              child: Text(
                'On hold: This household is not seeking at the moment, so '
                'the relationship cannot move forward. Your room stays open.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The ConsultationCard (Indawo Ephakeme), bronze-highlighted.
class ConsultationCard extends StatefulWidget {
  const ConsultationCard({
    super.key,
    required this.relationshipId,
    this.onChanged,
  });

  final String relationshipId;
  final VoidCallback? onChanged;

  @override
  State<ConsultationCard> createState() => _ConsultationCardState();
}

class _ConsultationCardState extends State<ConsultationCard> {
  MyConsultation? _data;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context
          .read(relationshipsRepoProvider)
          .myConsultation(widget.relationshipId);
      if (mounted) setState(() => _data = res);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  Future<void> _request() async {
    String mode = 'in_person';
    final availability = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Request Indawo Ephakeme consultation',
              style: T.headline.copyWith(fontSize: 21)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: mode,
                items: const [
                  DropdownMenuItem(value: 'in_person', child: Text('In person')),
                  DropdownMenuItem(value: 'video', child: Text('Video call')),
                  DropdownMenuItem(value: 'phone', child: Text('Phone call')),
                ],
                onChanged: (v) => setS(() => mode = v ?? 'in_person'),
                decoration:
                    const InputDecoration(labelText: 'Preferred mode', filled: true),
              ),
              TextField(
                controller: availability,
                decoration: const InputDecoration(
                    labelText: 'Your availability', filled: true),
              ),
              TextField(
                controller: note,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'A note (optional)', filled: true),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            GoldButton(
                label: 'Request', onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await context.read(relationshipsRepoProvider).requestConsultation(
            widget.relationshipId,
            mode: mode,
            availability: availability.text.trim(),
            note: note.text.trim(),
          );
      await _load();
      widget.onChanged?.call();
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
    final d = _data;
    return Container(
      decoration: BoxDecoration(
        color: C.crimson100,
        border: Border.all(color: C.crimson.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Indawo Ephakeme',
              style: T.headline.copyWith(fontSize: 20, color: C.crimson600)),
          const SizedBox(height: 4),
          Text(
            'Spiritual consultation before dating. Compulsory, and walked '
            'together.',
            style: TextStyle(fontSize: 12.5, color: C.crimson600.withOpacity(0.85)),
          ),
          const SizedBox(height: 10),
          if (_error != null) Text(_error!, style: const TextStyle(fontSize: 13)),
          if (d == null)
            const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            if (d.approvedLabel != null)
              Text(
                'Approved by Indawo Ephakeme for ${d.approvedLabel}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: C.sage),
              )
            else if (d.request == null) ...[
              TextButton(
                onPressed: _busy ? null : _request,
                child: Text('Request consultation',
                    style: T.bodyStrong.copyWith(color: C.crimson600)),
              ),
            ] else ...[
              _requestUi(d.request!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _requestUi(ConsultationRequest r) {
    final meId = context.read(backendProvider).userId;
    final mine = r.requesterId == meId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_statusText(r), style: const TextStyle(fontSize: 14, color: C.crimson600)),
        if (r.consultantName != null)
          Text('Consultant: ${r.consultantName}',
              style: const TextStyle(fontSize: 13, color: C.crimson600)),
        for (final sess in r.sessions) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sess.at == null
                            ? 'Session'
                            : Dates.fmt(DateTime.parse(sess.at!)),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_modeLabel(sess.mode)} · ${sess.status[0].toUpperCase()}${sess.status.substring(1)}',
                        style: const TextStyle(fontSize: 12, color: C.muted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final note = TextEditingController();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Request a new time'),
                        content: TextField(
                          controller: note,
                          decoration: const InputDecoration(
                              labelText: 'Why?', filled: true),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel')),
                          QuietButton(
                              label: 'Send',
                              onPressed: () => Navigator.of(ctx).pop(true)),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    try {
                      await context
                          .read(relationshipsRepoProvider)
                          .requestReschedule(sess.id, note.text.trim());
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyError(e))));
                      }
                    }
                  },
                  child: const Text('Reschedule', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
        if (r.outcome != null) ...[
          const SizedBox(height: 8),
          Text(
            _outcomeText(r),
            style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600, color: C.crimson600),
          ),
          if (r.outcomeSummary != null)
            Text(r.outcomeSummary!,
                style: const TextStyle(fontSize: 13, color: C.ink)),
        ],
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            if (r.status == 'awaiting_partner' && !mine) ...[
              PrimaryButton(
                label: 'Confirm',
                busy: _busy,
                onPressed: () => _respondConsult(r, true),
              ),
              QuietButton(
                label: 'Decline',
                busy: _busy,
                onPressed: () => _respondConsult(r, false),
              ),
            ],
            if (mine &&
                (r.status == 'awaiting_partner' ||
                    r.status == 'awaiting_assignment'))
              QuietButton(
                label: 'Withdraw request',
                busy: _busy,
                onPressed: () async {
                  try {
                    await context
                        .read(relationshipsRepoProvider)
                        .cancelConsultation(r.id);
                    await _load();
                    widget.onChanged?.call();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyError(e))));
                    }
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  String _statusText(ConsultationRequest r) {
    switch (r.status) {
      case 'awaiting_partner':
        return 'A request is waiting for confirmation.';
      case 'awaiting_assignment':
        return 'Waiting for a consultant.';
      case 'in_progress':
        return 'In progress with your consultant.';
      default:
        return r.status;
    }
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'video':
        return 'Video call';
      case 'phone':
        return 'Phone call';
      default:
        return 'In person';
    }
  }

  String _outcomeText(ConsultationRequest r) {
    switch (r.outcome) {
      case 'approved':
        return 'Approved';
      case 'not_yet_ready':
        return 'More time advised';
      case 'not_approved':
        return 'Not approved';
      default:
        return '';
    }
  }

  Future<void> _respondConsult(ConsultationRequest r, bool accept) async {
    setState(() => _busy = true);
    try {
      await context
          .read(relationshipsRepoProvider)
          .respondConsultation(r.id, accept);
      await _load();
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Household note shown in rooms connected to a household.
class HouseholdNote extends StatelessWidget {
  const HouseholdNote({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => BronzeInfoPanel(child: Text(text));
}
