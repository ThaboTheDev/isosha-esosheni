import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/contact_detection.dart';
import '../../core/widgets/chat_bubble.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/report_sheet.dart';
import '../../data/backend/backend.dart';
import '../../data/models/chat.dart';
import '../relationships/cards.dart';
import '../../data/models/relationship.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  ConversationInfo? _info;
  final List<ChatMessage> _messages = [];
  String? _error;
  final _draft = TextEditingController(text: _savedDraft);
  final _scroll = ScrollController();
  static String _savedDraft = '';

  final List<CancelWatch> _watches = [];
  Timer? _markReadDebounce;

  final _recorder = AudioRecorder();
  bool _recording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _applySecure(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final w in _watches) {
      w();
    }
    _markReadDebounce?.cancel();
    _recordTimer?.cancel();
    _recorder.dispose();
    _scroll.dispose();
    _draft.dispose();
    _applySecure(false);
    super.dispose();
  }

  Future<void> _applySecure(bool on) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('secure_chat') ?? true;
      if (!enabled) return;
      await const MethodChannel('com.trsh.isoshaesosheni/secure')
          .invokeMethod('set', on);
    } catch (_) {
      // Platform channel is optional (Android FLAG_SECURE).
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markRead();
    }
  }

  Future<void> _load() async {
    try {
      final repo = context.read(messagingRepoProvider);
      final bundle = await repo.conversation(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _info = bundle.info;
        _messages
          ..clear()
          ..addAll(bundle.messages.reversed);
      });
      _markRead();
      _subscribe();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  void _subscribe() {
    for (final w in _watches) {
      w();
    }
    _watches.clear();
    final repo = context.read(messagingRepoProvider);
    _watches.add(repo.watchMessages(widget.conversationId, (m) {
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((e) => e.id == m.id);
        if (i >= 0) {
          _messages[i] = m;
        } else {
          _messages.add(m);
        }
      });
      final meId = context.read(backendProvider).userId;
      if (m.senderId != null && m.senderId != meId) {
        _markRead();
        SemanticsService.announce(
          '${_info?.otherName ?? 'New message'}: ${m.body ?? 'media'}',
          TextDirection.ltr,
        );
      }
      _scrollToBottom();
    }));
    _watches.add(repo.watchReadReceipts(widget.conversationId, (uid, at) {
      if (!mounted) return;
      setState(() => _info = _info?.copyWith(otherReadAt: at));
    }));
    _watches.add(repo.watchReactions(widget.conversationId, (rec) {
      if (!mounted) return;
      final msgId = rec['message_id']?.toString();
      final emoji = rec['emoji']?.toString();
      final uid = rec['user_id']?.toString();
      if (msgId == null || emoji == null || uid == null) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.id == msgId);
        if (i < 0) return;
        final m = _messages[i];
        final reactions = {
          for (final e in m.reactions.entries)
            e.key: List<String>.from(e.value),
        };
        final users = reactions.putIfAbsent(emoji, () => []);
        if (users.contains(uid)) {
          users.remove(uid);
          if (users.isEmpty) reactions.remove(emoji);
        } else {
          users.add(uid);
        }
        _messages[i] = m.copyWith(reactions: reactions);
      });
    }));
  }

  void _markRead() {
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        await context
            .read(messagingRepoProvider)
            .markRead(widget.conversationId);
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ------------------------------------------------------------------
  Future<void> _sendText() async {
    final body = _draft.text.trim();
    if (body.isEmpty) return;
    if (body.length > 4000) return;
    final warn = ContactDetection.looksLikeContactDetails(body);
    _draft.clear();
    _savedDraft = '';
    try {
      await context
          .read(messagingRepoProvider)
          .sendText(widget.conversationId, body);
      HapticFeedback.lightImpact();
    } catch (e) {
      _draft.text = body;
      _savedDraft = body;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
      return;
    }
    if (warn && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ContactDetection.warning),
          backgroundColor: C.crimson600,
          duration: const Duration(seconds: 6),
        ),
      );
    }
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Allow photo access in your settings to send a '
                'photo.')));
      }
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 8 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Photos can be up to 8 MB.')));
      }
      return;
    }
    final ext = (file.name.split('.').last).toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Use a JPG, PNG or WebP image.')));
      }
      return;
    }
    try {
      await context.read(messagingRepoProvider).uploadAndSendMedia(
            widget.conversationId,
            'image',
            bytes,
            ext: ext,
            contentType: file.mimeType ?? 'image/$ext',
          );
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _pickVideo() async {
    if (_info?.videoEnabled != true) return;
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: _info!.maxVideoSeconds),
    );
    if (file == null) return;
    // Verify duration with video_player before upload.
    VideoPlayerController? ctl;
    try {
      ctl = VideoPlayerController.file(File(file.path));
      await ctl.initialize();
      if (ctl.value.duration.inSeconds > _info!.maxVideoSeconds) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Videos can be up to ${_info!.maxVideoSeconds} seconds.')));
        }
        return;
      }
    } catch (_) {} finally {
      await ctl?.dispose();
    }
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Videos can be up to 50 MB.')));
      }
      return;
    }
    final ext = file.name.split('.').last.toLowerCase();
    try {
      await context.read(messagingRepoProvider).uploadAndSendMedia(
            widget.conversationId,
            'video',
            bytes,
            ext: ext,
            contentType: file.mimeType ?? 'video/$ext',
            mediaSeconds: ctl?.value.duration.inSeconds,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _startRecording() async {
    final granted = await _recorder.hasPermission();
    if (!granted) {
      final st = await Permission.microphone.request();
      if (!st.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Allow microphone access in your settings to '
                  'record a voice note.')));
        }
        return;
      }
    }
    final path =
        '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _recording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
        setState(() => _recordSeconds++);
        if (_recordSeconds >= (_info?.maxVoiceSeconds ?? 120)) {
          await _stopRecording(send: true);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _stopRecording({required bool send}) async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    final seconds = _recordSeconds;
    setState(() {
      _recording = false;
      _recordSeconds = 0;
    });
    if (!send || path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    try {
      await context.read(messagingRepoProvider).uploadAndSendMedia(
            widget.conversationId,
            'voice',
            bytes,
            ext: 'm4a',
            contentType: 'audio/mp4',
            mediaSeconds: seconds.clamp(1, _info?.maxVoiceSeconds ?? 120),
          );
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  void _messageMenu(ChatMessage m) {
    final meId = context.read(backendProvider).userId;
    final mine = m.senderId == meId;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 6,
                children: [
                  for (final emoji in _info?.reactions ?? const ['❤️', '🙏'])
                    InkWell(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        try {
                          await context
                              .read(messagingRepoProvider)
                              .react(m.id, emoji);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(friendlyError(e))));
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
            ),
            if (mine)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: C.rust),
                title: const Text('Delete for both of you'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c2) => AlertDialog(
                      title: const Text('Delete this message for both of you?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(c2).pop(false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.of(c2).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: C.rust))),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await context
                          .read(messagingRepoProvider)
                          .deleteMessage(m.id);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(friendlyError(e))));
                      }
                    }
                  }
                },
              ),
            if (!mine && m.senderId != null)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: C.rust),
                title: const Text('Report this message'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await ReportSheet.show(
                    context,
                    title: 'Report message',
                    onSubmit: (category, details) async {
                      try {
                        await context.read(discoveryRepoProvider).reportMember(
                              m.senderId!,
                              category,
                              details,
                              conv: widget.conversationId,
                              msg: m.id,
                            );
                        return null;
                      } catch (e) {
                        return friendlyError(e);
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final meId = context.read(backendProvider).userId;
    return Scaffold(
      appBar: BrandHeader(
        showMenu: false,
        title: _info?.otherName ?? 'Conversation',
      ),
      body: Column(
        children: [
          _headerRow(),
          const Divider(height: 1, color: C.line),
          Expanded(
            child: _error != null
                ? ErrorInline(message: _error!, onRetry: _load)
                : _info == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (var i = 0; i < _messages.length; i++) ...[
                            if (i == 0 ||
                                Dates.dayLabel(
                                        DateTime.parse(_messages[i].createdAt)) !=
                                    Dates.dayLabel(DateTime.parse(
                                        _messages[i - 1].createdAt)))
                              _daySeparator(_messages[i].createdAt),
                            _bubble(_messages[i], meId),
                          ],
                        ],
                      ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Material(
      color: C.surface,
      child: InkWell(
        onTap: () {
          final other = _info?.otherId;
          if (other != null) context.go('/members/$other');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Avatar(name: _info?.otherName, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_info?.otherName ?? '',
                        style: T.bodyStrong.copyWith(fontSize: 15)),
                    const Text(
                      'View profile · Relationship details',
                      style: TextStyle(fontSize: 11.5, color: C.muted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'report':
                      final other = _info?.otherId;
                      if (other == null) return;
                      await ReportSheet.show(
                        context,
                        title: 'Report this conversation',
                        onSubmit: (category, details) async {
                          try {
                            await context
                                .read(discoveryRepoProvider)
                                .reportMember(other, category, details,
                                    conv: widget.conversationId);
                            return null;
                          } catch (e) {
                            return friendlyError(e);
                          }
                        },
                      );
                    case 'block':
                      final other = _info?.otherId;
                      if (other == null) return;
                      try {
                        await context.read(discoveryRepoProvider).block(other);
                        if (mounted) context.go('/messages');
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(friendlyError(e))));
                        }
                      }
                    case 'end_match':
                      final other = _info?.otherId;
                      if (other == null) return;
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c2) => AlertDialog(
                          title: Text(
                              'End your match with ${_info?.otherName ?? ''}?'),
                          content: const Text(
                              'You can still find each other again later.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(c2).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.of(c2).pop(true),
                                child: const Text('End match',
                                    style: TextStyle(color: C.rust))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        try {
                          await context
                              .read(discoveryRepoProvider)
                              .endMatch(other);
                          if (mounted) context.go('/messages');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(friendlyError(e))));
                          }
                        }
                      }
                    case 'details':
                      _relationshipSheet();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'details', child: Text('Relationship details')),
                  const PopupMenuItem(value: 'report', child: Text('Report this conversation')),
                  const PopupMenuItem(value: 'end_match', child: Text('End match')),
                  const PopupMenuItem(value: 'block', child: Text('Block')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _relationshipSheet() {
    final rel = _info?.relationship;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, ctl) => ListView(
          controller: ctl,
          padding: const EdgeInsets.all(16),
          children: [
            if (rel != null) ...[
              RelationshipCard(
                state: RelationshipState.fromJson(rel),
                myId: meIdForSheet(),
                onChanged: _load,
              ),
              const SizedBox(height: 12),
              ConsultationCard(
                relationshipId: (rel['id'] as String?) ?? '',
                onChanged: _load,
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.plum100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keeping this space safe',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(
                    'Never send money or share banking details. Meet in '
                    'public, and tell someone you trust, if you choose to '
                    'meet.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? meIdForSheet() => context.read(backendProvider).userId;

  Widget _daySeparator(String iso) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: C.plum100,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          Dates.dayLabel(DateTime.parse(iso)),
          style: const TextStyle(fontSize: 11.5, color: C.plum700),
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m, String? meId) {
    final mine = m.senderId == meId;
    final isLast = _messages.last.id == m.id;
    final otherRead = _info?.otherReadAt;
    final read = mine &&
        isLast &&
        otherRead != null &&
        otherRead.compareTo(m.createdAt) >= 0;
    return ChatBubble(
      createdAt: m.createdAt,
      mine: mine,
      kind: m.kind,
      body: m.body,
      deleted: m.deleted,
      isLast: isLast,
      read: read,
      reactions: m.reactions,
      onLongPress: m.deleted ? null : () => _messageMenu(m),
      child: m.kind == 'text' ? null : _body(m, mine),
    );
  }

  Widget _body(ChatMessage m, bool mine) {
    switch (m.kind) {
      case 'text':
        return const SizedBox.shrink();
      case 'image':
        return FutureBuilder<String?>(
          future: context
              .read(messagingRepoProvider)
              .chatMediaUrl(m.mediaPath)
              .then((u) => u.isEmpty ? null : u),
          builder: (ctx, snap) {
            if (snap.data == null) {
              return const SizedBox(
                width: 180,
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(snap.data!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined)),
            );
          },
        );
      case 'voice':
        return _VoicePlayer(
          path: m.mediaPath,
          seconds: m.mediaSeconds,
          light: mine,
        );
      case 'video':
        return FutureBuilder<String?>(
          future: context
              .read(messagingRepoProvider)
              .chatMediaUrl(m.mediaPath)
              .then((u) => u.isEmpty ? null : u),
          builder: (ctx, snap) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: mine ? Colors.white12 : C.plum50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline,
                      color: mine ? Colors.white : C.royal),
                  const SizedBox(width: 6),
                  Text(
                    'Video${m.mediaSeconds != null ? ' · ${m.mediaSeconds}s' : ''}',
                    style: TextStyle(
                        fontSize: 13, color: mine ? Colors.white : C.ink),
                  ),
                ],
              ),
            );
          },
        );
      default:
        return Text(
          m.body ?? '',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: mine ? Colors.white : C.ink,
          ),
        );
    }
  }

  Widget _composer() {
    if (_info?.closed == true) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        color: C.plum100,
        child: const Text(
          'This connection has ended. The conversation is kept read-only.',
          style: TextStyle(fontSize: 13, color: C.plum700),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Container(
      color: C.surface,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: _recording
          ? Row(
              children: [
                const Icon(Icons.mic, color: C.rust),
                const SizedBox(width: 8),
                Text(
                  '${_recordSeconds ~/ 60}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                  style: T.bodyStrong,
                ),
                const Expanded(child: SizedBox()),
                TextButton(
                  onPressed: () => _stopRecording(send: false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => _stopRecording(send: true),
                  child: const Text('Send',
                      style: TextStyle(color: C.royal, fontWeight: FontWeight.w700)),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.attach_file, color: C.muted),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'photo', child: Text('Photo')),
                    if (_info?.videoEnabled == true)
                      const PopupMenuItem(value: 'video', child: Text('Video')),
                  ],
                  onSelected: (v) {
                    if (v == 'photo') {
                      _pickImage();
                    } else {
                      _pickVideo();
                    }
                  },
                ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _draft,
                      maxLines: null,
                      maxLength: 4000,
                      onChanged: (v) => _savedDraft = v,
                      decoration: const InputDecoration(
                        hintText: 'Write a kind message',
                        border: InputBorder.none,
                        filled: false,
                        counterText: '',
                      ),
                    ),
                  ),
                ),
                if (_draft.text.trim().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.send, color: C.royal),
                    onPressed: _sendText,
                    tooltip: 'Send',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.mic, color: C.royal),
                    onPressed: _startRecording,
                    tooltip: 'Record a voice note',
                  ),
              ],
            ),
    );
  }
}

class ErrorInline extends StatelessWidget {
  const ErrorInline({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: T.small),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
}

class _VoicePlayer extends StatefulWidget {
  const _VoicePlayer({this.path, this.seconds, this.light = false});
  final String? path;
  final int? seconds;
  final bool light;

  @override
  State<_VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<_VoicePlayer> {
  AudioPlayer? _player;
  bool _playing = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_player == null) {
      final url = await context
          .read(messagingRepoProvider)
          .chatMediaUrl(widget.path);
      _player = AudioPlayer();
      await _player!.setUrl(url);
      _player!.playerStateStream.listen((s) {
        if (mounted) {
          setState(() => _playing = s.playing);
        }
      });
    }
    if (_playing) {
      await _player!.pause();
    } else {
      await _player!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.light ? Colors.white : C.royal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _toggle,
          child: Icon(
            _playing ? Icons.pause_circle_outline : Icons.play_circle_outline,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.graphic_eq, color: color.withOpacity(0.7), size: 18),
        const SizedBox(width: 6),
        Text(
          widget.seconds == null
              ? ''
              : '${widget.seconds! ~/ 60}:${(widget.seconds! % 60).toString().padLeft(2, '0')}',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
