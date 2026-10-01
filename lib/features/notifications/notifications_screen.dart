import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/utils/safe_next.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/loading.dart';
import '../../data/models/misc.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context.read(messagingRepoProvider).notifications();
      if (mounted) setState(() => _rows = rows);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Notifications'),
      body: Column(
        children: [
          Expanded(
            child: _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : _rows == null
                    ? const LoadingPanel()
                    : _rows!.isEmpty
                        ? const EmptyState(
                            message: 'No notifications yet.',
                            icon: Icons.notifications_outlined,
                          )
                        : ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    try {
                                      await context
                                          .read(messagingRepoProvider)
                                          .markNotificationsRead();
                                      _load();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    friendlyError(e))));
                                      }
                                    }
                                  },
                                  child: const Text('Mark all read',
                                      style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              for (final n in _rows!) _row(n),
                            ],
                          ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Email and phone notifications will be added later. For now, '
              'notices appear here and on the bell.',
              style: TextStyle(fontSize: 11.5, color: C.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppNotification n) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        try {
          await context
              .read(messagingRepoProvider)
              .markNotificationsRead(ids: [n.id]);
        } catch (_) {}
        if (n.link != null && n.link!.startsWith('/')) {
          if (mounted) context.go(safeNext(n.link));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.surface,
          border: Border.all(color: C.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (n.unread)
              const Padding(
                padding: EdgeInsets.only(right: 8, top: 6),
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: C.crimson, shape: BoxShape.circle),
                  child: SizedBox(width: 8, height: 8),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          n.unread ? FontWeight.w700 : FontWeight.w500,
                      color: C.ink,
                    ),
                  ),
                  if (n.body != null)
                    Text(n.body!,
                        style: T.small.copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(Dates.timeAgo(DateTime.parse(n.createdAt)),
                      style: T.small.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
