import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme/theme.dart';
import 'core/widgets/announcement_dialog.dart';
import 'data/models/misc.dart';
import 'data/repositories/account_repo.dart';
import 'data/repositories/safety_repo.dart';

class IsoshaApp extends ConsumerStatefulWidget {
  const IsoshaApp({super.key});

  @override
  ConsumerState<IsoshaApp> createState() => _IsoshaAppState();
}

class _IsoshaAppState extends ConsumerState<IsoshaApp>
    with WidgetsBindingObserver {
  final List<Announcement> _queue = [];
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foregroundRefresh();
    }
  }

  Future<void> _foregroundRefresh() async {
    final backend = ref.read(backendProvider);
    if (!backend.signedIn) return;
    try {
      await SafetyRepository(backend).expireSanctions();
    } catch (_) {}
    ref.invalidate(announcementsProvider);
    ref.invalidate(liveNowProvider);
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(matchSummaryProvider);
    ref.read(sessionProvider.notifier).reload();
  }

  void _pumpAnnouncements() {
    if (_showing) return;
    final anns = ref.read(announcementsProvider).valueOrNull;
    if (anns == null || anns.isEmpty) return;
    _queue
      ..clear()
      ..addAll(anns.map(Announcement.fromJson));
    _showNext();
  }

  void _showNext() {
    if (_queue.isEmpty) {
      _showing = false;
      return;
    }
    _showing = true;
    final a = _queue.removeAt(0);
    AnnouncementDialog.show(
      context,
      a,
      hasNext: _queue.isNotEmpty,
      onDismiss: () {
        Navigator.of(context).pop();
        AccountRepository(
          ref.read(backendProvider),
          ref.read(signedUrlCacheProvider),
        ).dismissAnnouncement(a.id).catchError((_) => null);
        ref.invalidate(announcementsProvider);
        _showNext();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(announcementsProvider, (_, __) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pumpAnnouncements();
      });
    });
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Isosha Esosheni',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('en', 'ZA'),
      supportedLocales: const [Locale('en', 'ZA'), Locale('en')],
      routerConfig: router,
    );
  }
}
