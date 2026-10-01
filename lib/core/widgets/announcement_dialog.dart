import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../data/models/misc.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'buttons.dart';

/// Modal announcement with the tone header colours from the design system.
class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({
    super.key,
    required this.announcement,
    required this.onDismiss,
    this.hasNext = false,
  });

  final Announcement announcement;
  final VoidCallback onDismiss;
  final bool hasNext;

  static void show(BuildContext context, Announcement a,
      {required VoidCallback onDismiss, bool hasNext = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss announcement',
      barrierColor: C.plum800.withOpacity(0.55),
      pageBuilder: (_, __, ___) => AnnouncementDialog(
        announcement: a,
        onDismiss: onDismiss,
        hasNext: hasNext,
      ),
    );
  }

  Gradient get _tone {
    switch (announcement.tone) {
      case 'celebration':
        return C.toneCelebration;
      case 'urgent':
        return C.toneUrgent;
      default:
        return C.toneNotice;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: C.panelShadow(),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: _tone,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.headerLabel.toUpperCase(),
                      style: T.eyebrowOnDark,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.title,
                      style: T.headline.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(announcement.body, style: T.body),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (announcement.linkUrl != null) ...[
                          QuietButton(
                            label: announcement.linkLabel ?? 'Open',
                            onPressed: () async {
                              onDismiss();
                              final link = announcement.linkUrl!;
                              if (link.startsWith('/')) {
                                context.go(link);
                              } else {
                                await launchUrl(Uri.parse(link),
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        PrimaryButton(
                          label: hasNext ? 'Next' : 'Close',
                          onPressed: onDismiss,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the web base URL is needed for in-app pages.
String webUrlFor(String path) => AppConfig.webBaseUrl + path;
