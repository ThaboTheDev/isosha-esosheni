import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/media_urls.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/panel.dart';
import '../../data/backend/backend.dart';
import '../../data/models/conference.dart';

class ConferencesScreen extends ConsumerStatefulWidget {
  const ConferencesScreen({super.key});

  @override
  ConsumerState<ConferencesScreen> createState() => _ConferencesScreenState();
}

class _ConferencesScreenState extends ConsumerState<ConferencesScreen> {
  List<ConferenceSummary>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context.read(conferencesRepoProvider).list();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  String _seats(ConferenceSummary c) {
    if (c.capacity == null) return 'Open attendance';
    if ((c.seatsLeft ?? 0) <= 0) return 'Full, waiting list open';
    return '${c.seatsLeft} of ${c.capacity} places left';
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider).valueOrNull ?? const <String>[];
    final speaker = perms.contains('conferences.speak');
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Love Life Conferences'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _rows == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (speaker)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuietButton(
                          label: 'My speaking sessions',
                          icon: Icons.record_voice_over_outlined,
                          onPressed: () => context.go('/conferences/speaking'),
                        ),
                      ),
                    if (_rows!.isEmpty)
                      const EmptyState(
                        message: 'No conferences announced right now.',
                        icon: Icons.event_outlined,
                      ),
                    for (final c in _rows!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Eyebrow(c.kind),
                              const SizedBox(height: 4),
                              Text(c.title, style: T.headline.copyWith(fontSize: 22)),
                              if (c.summary != null)
                                Text(c.summary!,
                                    style: T.body.copyWith(fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(
                                [
                                  c.format,
                                  [c.city, c.province]
                                      .where((e) => (e ?? '').isNotEmpty)
                                      .join(', '),
                                  if (c.startsAt != null)
                                    '${Dates.fmtDate(DateTime.parse(c.startsAt!))}'
                                        '${c.endsAt != null ? ' – ${Dates.fmtDate(DateTime.parse(c.endsAt!))}' : ''}',
                                ].where((e) => e != null && e.isNotEmpty).join(' · '),
                                style: T.small,
                              ),
                              const SizedBox(height: 4),
                              Text(_seats(c),
                                  style: const TextStyle(
                                      fontSize: 12.5, color: C.crimson600,
                                      fontWeight: FontWeight.w600)),
                              if (c.audience != null)
                                Text('For: ${c.audience}',
                                    style: T.small.copyWith(fontSize: 12)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final s in c.speakers)
                                    ChipSmallLite(s.name ?? ''),
                                  if (c.recordings > 0)
                                    ChipSmallLite(
                                        '${c.recordings} recordings'),
                                  if (c.registration != null)
                                    ChipSmallLite(
                                        c.registration == 'registered'
                                            ? 'Registered'
                                            : 'Waitlisted',
                                        color: C.sage100,
                                        textColor: C.sage),
                                ],
                              ),
                              const SizedBox(height: 10),
                              PrimaryButton(
                                label: 'Details',
                                onPressed: () =>
                                    context.go('/conferences/${c.id}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class ChipSmallLite extends StatelessWidget {
  const ChipSmallLite(this.label, {super.key, this.color, this.textColor});
  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? C.plum100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: textColor ?? C.plum700,
              fontWeight: FontWeight.w500)),
    );
  }
}

class ConferenceDetailScreen extends StatefulWidget {
  const ConferenceDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ConferenceDetailScreen> createState() =>
      _ConferenceDetailScreenState();
}

class _ConferenceDetailScreenState extends State<ConferenceDetailScreen> {
  ConferenceDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await context.read(conferencesRepoProvider).detail(widget.id);
      if (mounted) setState(() => _detail = d);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  Future<void> _register() async {
    try {
      final res = await context
          .read(conferencesRepoProvider)
          .register(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(res == 'waitlisted'
                ? 'You are on the waiting list.'
                : 'Registered. See you there.')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Conference'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : d == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (d.cancelledReason != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: C.rust100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Cancelled: ${d.cancelledReason}',
                          style: const TextStyle(color: C.rust, fontSize: 13),
                        ),
                      ),
                    Eyebrow(d.kind),
                    Text(d.title, style: T.display),
                    if (d.summary != null)
                      Text(d.summary!, style: T.body.copyWith(fontSize: 15)),
                    const SizedBox(height: 12),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (d.startsAt != null)
                            _sideRow('Dates',
                                '${Dates.fmtDate(DateTime.parse(d.startsAt!))}'
                                '${d.endsAt != null ? ' – ${Dates.fmtDate(DateTime.parse(d.endsAt!))}' : ''}'),
                          _sideRow('Format',
                              [d.format, d.venue]
                                  .where((e) => (e ?? '').isNotEmpty)
                                  .join(' · ')),
                          _sideRow('Audience & seats',
                              '${d.audience ?? 'Members'} · ${d.capacity == null ? 'Open attendance' : (d.seatsLeft ?? 0) <= 0 ? 'Full, waiting list open' : '${d.seatsLeft} of ${d.capacity} places left'}'),
                          if (d.registrationClosesAt != null)
                            _sideRow('Registration closes',
                                Dates.fmt(DateTime.parse(d.registrationClosesAt!))),
                          const SizedBox(height: 10),
                          _registerControls(d),
                        ],
                      ),
                    ),
                    if (d.description != null) ...[
                      const SizedBox(height: 12),
                      Text(d.description!, style: T.body.copyWith(fontSize: 14.5)),
                    ],
                    const SizedBox(height: 16),
                    Text('Programme', style: T.headline.copyWith(fontSize: 22)),
                    const SizedBox(height: 8),
                    for (final s in d.sessions) _session(context, s, d),
                  ],
                ),
    );
  }

  Widget _sideRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: T.small.copyWith(fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _registerControls(ConferenceDetail d) {
    if (d.cancelledReason != null) return const SizedBox.shrink();
    switch (d.registration) {
      case 'registered':
        return Wrap(
          spacing: 8,
          children: [
            ChipSmallLite('Registered', color: C.sage100, textColor: C.sage),
            QuietButton(
              label: 'Cancel registration',
              onPressed: () async {
                try {
                  await context
                      .read(conferencesRepoProvider)
                      .cancelRegistration(widget.id);
                  _load();
                } catch (e) {
                  _toast(e);
                }
              },
            ),
          ],
        );
      case 'waitlisted':
        return Wrap(
          spacing: 8,
          children: [
            ChipSmallLite(
              d.waitlistPosition == null
                  ? 'Waitlisted'
                  : 'You are number ${d.waitlistPosition} on the waiting list',
              color: C.crimson100,
              textColor: C.crimson600,
            ),
            QuietButton(
              label: 'Cancel',
              onPressed: () async {
                try {
                  await context
                      .read(conferencesRepoProvider)
                      .cancelRegistration(widget.id);
                  _load();
                } catch (e) {
                  _toast(e);
                }
              },
            ),
          ],
        );
      default:
        return GoldButton(label: 'Register', onPressed: _register);
    }
  }

  Widget _session(BuildContext context, ConferenceSession s, ConferenceDetail d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.startsAt != null)
              Text(
                '${Dates.fmtTime(DateTime.parse(s.startsAt!))}'
                '${s.endsAt != null ? ' – ${Dates.fmtTime(DateTime.parse(s.endsAt!))}' : ''}',
                style: T.small.copyWith(fontSize: 12),
              ),
            Text(s.title ?? 'Session', style: T.headline.copyWith(fontSize: 19)),
            if (s.speaker?.name != null)
              _SpeakerBio(speaker: s.speaker!),
            if (s.description != null)
              Text(s.description!, style: T.body.copyWith(fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (s.liveUrl != null)
                  PrimaryButton(
                    label: 'Join live',
                    onPressed: () => context.go(
                        '/conferences/${d.id}/live/${s.id}'),
                  )
                else if (d.registration == null)
                  ChipSmallLite('Register to receive the live link',
                      color: C.crimson100, textColor: C.crimson600)
                else
                  QuietButton(
                    label: 'Live room',
                    onPressed: () =>
                        context.go('/conferences/${d.id}/live/${s.id}'),
                  ),
                if (s.recordingUrl != null)
                  QuietButton(
                    label: 'Watch the recording',
                    onPressed: () => launchUrl(Uri.parse(s.recordingUrl!),
                        mode: LaunchMode.externalApplication),
                  )
                else if (d.registration == null)
                  const ChipSmallLite('The recording is for registered members.')
              ],
            ),
            if (s.questions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Your questions', style: T.bodyStrong.copyWith(fontSize: 13)),
              for (final q in s.questions)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• ${q.body}${q.anonymous ? ' (anonymous)' : ''}'
                    '${q.answered ? ' — Answered.' : ''}',
                    style: T.small.copyWith(fontSize: 12.5),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            _AskQuestion(session: s, registered: d.registration != null),
          ],
        ),
      ),
    );
  }

  void _toast(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

class _SpeakerBio extends StatefulWidget {
  const _SpeakerBio({required this.speaker});
  final ConferenceSpeaker speaker;

  @override
  State<_SpeakerBio> createState() => _SpeakerBioState();
}

class _SpeakerBioState extends State<_SpeakerBio> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.speaker.bio == null
              ? null
              : () => setState(() => _open = !_open),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.speaker.name}'
                '${widget.speaker.title != null ? ' · ${widget.speaker.title}' : ''}',
                style: T.small.copyWith(fontSize: 12.5, color: C.crimson600),
              ),
              if (widget.speaker.bio != null)
                Icon(_open ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: C.muted),
            ],
          ),
        ),
        if (_open && widget.speaker.bio != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(widget.speaker.bio!,
                style: T.small.copyWith(fontSize: 12.5)),
          ),
      ],
    );
  }
}

class _AskQuestion extends StatefulWidget {
  const _AskQuestion({required this.session, required this.registered});
  final ConferenceSession session;
  final bool registered;

  @override
  State<_AskQuestion> createState() => _AskQuestionState();
}

class _AskQuestionState extends State<_AskQuestion> {
  final _body = TextEditingController();
  bool _anonymous = false;
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.registered) {
      return const Text('Register to ask the speaker a question.',
          style: TextStyle(fontSize: 12, color: C.muted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ask the speaker',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _body,
          maxLines: 2,
          maxLength: 500,
          decoration:
              const InputDecoration(hintText: 'Your question', filled: true),
        ),
        Row(
          children: [
            Checkbox(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v ?? false),
            ),
            const Text('Ask anonymously', style: TextStyle(fontSize: 13)),
            const Expanded(child: SizedBox()),
            QuietButton(
              label: 'Send question',
              busy: _busy,
              onPressed: () async {
                final body = _body.text.trim();
                if (body.isEmpty) return;
                setState(() => _busy = true);
                try {
                  await context.read(conferencesRepoProvider).askQuestion(
                      widget.session.id, body,
                      anonymous: _anonymous);
                  _body.clear();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(friendlyError(e))));
                  }
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// The live room: embed / external join + realtime chat.
class LiveRoomScreen extends StatefulWidget {
  const LiveRoomScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  LiveRoom? _room;
  String? _error;
  Timer? _poll;
  CancelWatch? _chatWatch;
  final _chatDraft = TextEditingController();
  WebViewController? _webCtl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _chatWatch?.call();
    _chatDraft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final room = await context
          .read(conferencesRepoProvider)
          .liveRoom(widget.sessionId);
      if (!mounted) return;
      final wasLive = _room?.status == 'live';
      setState(() => _room = room);
      if (room.status == 'live' && !wasLive) {
        _setupStage();
      }
      if (room.status != 'ended') {
        _poll ??= Timer.periodic(const Duration(seconds: 18), (_) async {
          try {
            final r = await context
                .read(conferencesRepoProvider)
                .liveRoom(widget.sessionId);
            if (!mounted) return;
            if (r.status != _room?.status) {
              setState(() => _room = r);
              if (r.status == 'live') _setupStage();
            }
          } catch (_) {}
        });
      }
      _chatWatch ??= context
          .read(conferencesRepoProvider)
          .watchLiveChat(widget.sessionId, (m) {
        if (!mounted) return;
        setState(() => _room = _room?.copyWith(chat: [..._room!.chat, m]));
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  void _setupStage() {
    final room = _room;
    if (room == null) return;
    if (room.kind == 'youtube') {
      final id = MediaUrls.extractYouTubeId(room.url);
      if (id != null) {
        final ctl = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(MediaUrls.youTubeEmbedUrl(id)));
        setState(() => _webCtl = ctl);
      }
    } else if (room.kind == 'jitsi') {
      final name = context.read(sessionProvider).me?.fullName ?? 'Member';
      final ctl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(
            MediaUrls.jitsiUrl(room.jitsiDomain ?? 'meet.jit.si', room.room ?? '', name)));
      setState(() => _webCtl = ctl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Live room'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : room == null
              ? const LoadingPanel()
              : Column(
                  children: [
                    Expanded(child: _stage(room)),
                    if (room.allowed) _chat(room),
                  ],
                ),
    );
  }

  Widget _stage(LiveRoom room) {
    if (room.status != 'live') {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: C.brandHeader,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                room.status == 'ended'
                    ? 'This session has ended'
                    : 'The session has not started yet',
                style: T.headline.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                room.status == 'ended'
                    ? ''
                    : 'Stay on this page. It opens by itself when the '
                        'speaker goes live.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              if (room.status == 'ended' && room.recordingUrl != null)
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(room.recordingUrl!),
                      mode: LaunchMode.externalApplication),
                  child: const Text('Watch the recording',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
      );
    }
    switch (room.kind) {
      case 'youtube':
      case 'jitsi':
        if (_webCtl != null) {
          return WebViewWidget(controller: _webCtl!);
        }
        return const LoadingPanel();
      case 'zoom':
        return _joinCard('Join on Zoom', room.url);
      case 'link':
        return _joinCard('Join the session', room.url);
      default:
        return const Center(child: Text('The session link is not available.'));
    }
  }

  Widget _joinCard(String label, String? url) {
    return Center(
      child: PrimaryButton(
        label: label,
        onPressed: url == null
            ? null
            : () => launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication),
      ),
    );
  }

  Widget _chat(LiveRoom room) {
    return Container(
      color: C.surface,
      height: 220,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (final m in room.chat)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${m.authorName ?? 'Member'}: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: m.speaker ? C.crimson600 : C.plum700,
                            ),
                          ),
                          TextSpan(
                            text: m.body,
                            style: const TextStyle(
                                fontSize: 13, color: C.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatDraft,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    hintText: 'Say something kind',
                    border: InputBorder.none,
                    filled: false,
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, size: 18, color: C.royal),
                onPressed: () async {
                  final body = _chatDraft.text.trim();
                  if (body.isEmpty) return;
                  _chatDraft.clear();
                  try {
                    await context
                        .read(conferencesRepoProvider)
                        .sendLiveChat(widget.sessionId, body);
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
      ),
    );
  }
}

/// Speaker tools (role-gated).
class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  List<SpeakingSession>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context.read(conferencesRepoProvider).mySpeaking();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'My speaking'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _rows == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_rows!.isEmpty)
                      const EmptyState(
                          message: 'No speaking sessions assigned.',
                          icon: Icons.record_voice_over_outlined),
                    for (final s in _rows!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Panel(
                          child: _SessionEditor(session: s, onSaved: _load),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _SessionEditor extends StatefulWidget {
  const _SessionEditor({required this.session, required this.onSaved});
  final SpeakingSession session;
  final VoidCallback onSaved;

  @override
  State<_SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends State<_SessionEditor> {
  late final TextEditingController _desc =
      TextEditingController(text: widget.session.description);
  late final TextEditingController _live =
      TextEditingController(text: widget.session.liveUrl);
  late final TextEditingController _rec =
      TextEditingController(text: widget.session.recordingUrl);

  @override
  void dispose() {
    _desc.dispose();
    _live.dispose();
    _rec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.title ?? 'Session', style: T.headline.copyWith(fontSize: 19)),
        if (s.conferenceTitle != null)
          Text(s.conferenceTitle!, style: T.small),
        const SizedBox(height: 8),
        TextField(
          controller: _desc,
          maxLines: 2,
          decoration:
              const InputDecoration(labelText: 'Description', filled: true),
        ),
        TextField(
          controller: _live,
          decoration:
              const InputDecoration(labelText: 'Live URL', filled: true),
        ),
        TextField(
          controller: _rec,
          decoration: const InputDecoration(
              labelText: 'Recording URL', filled: true),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            QuietButton(
              label: 'Save',
              onPressed: () async {
                try {
                  await context
                      .read(conferencesRepoProvider)
                      .updateMySession(
                        s.id,
                        description: _desc.text.trim(),
                        liveUrl: _live.text.trim(),
                        recordingUrl: _rec.text.trim(),
                      );
                  widget.onSaved();
                } catch (e) {
                  _toast(e);
                }
              },
            ),
            if (s.status != 'live')
              GoldButton(
                label: 'Go live',
                onPressed: () async {
                  try {
                    await context.read(conferencesRepoProvider).goLive(
                        s.id, _live.text.contains('youtu') ? 'youtube' : 'link',
                        url: _live.text.trim());
                    widget.onSaved();
                  } catch (e) {
                    _toast(e);
                  }
                },
              )
            else
              DangerStop(
                onEnd: () async {
                  try {
                    await context
                        .read(conferencesRepoProvider)
                        .endLive(s.id, recording: _rec.text.trim());
                    widget.onSaved();
                  } catch (e) {
                    _toast(e);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  void _toast(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }
}

class DangerStop extends StatelessWidget {
  const DangerStop({super.key, required this.onEnd});
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) =>
      DangerButton(label: 'End live', onPressed: onEnd);
}
