import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'avatar.dart';
import 'panel.dart';

/// Teal gradient header with crest, title, bell and avatar menu.
class BrandHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeader({super.key, this.showMenu = true, this.title});

  final bool showMenu;
  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: C.brandHeader),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 62,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/crest.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title ?? 'Isosha Esosheni',
                          style: TextStyle(
                            fontFamily: T.headingFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'The Revelation Spiritual Home Kingdom',
                          style: T.eyebrowOnDark.copyWith(fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showMenu) ...[
                    _BellButton(),
                    const SizedBox(width: 4),
                    _AvatarMenu(),
                    const SizedBox(width: 10),
                  ] else
                    const SizedBox(width: 12),
                ],
              ),
            ),
            const BrandBar(),
          ],
        ),
      ),
    );
  }
}

class _BellButton extends ConsumerWidget {
  const _BellButton();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    return Semantics(
      label: 'Notifications, $unread unread',
      button: true,
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white),
            onPressed: () => context.go('/notifications'),
          ),
          if (unread > 0)
            Positioned(
              right: 8,
              top: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                decoration: const BoxDecoration(
                  color: C.crimson,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarMenu extends ConsumerWidget {
  const _AvatarMenu();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final perms = ref.watch(permissionsProvider).valueOrNull ?? const <String>[];
    final me = session.me;
    final canConsult = perms.contains('consultations.handle') ||
        perms.contains('consultations.super') ||
        perms.contains('relationships.manage');
    final isAdmin = perms.contains('admin.access') ||
        perms.contains('members.manage');

    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: Avatar(
        name: me?.preferredName ?? me?.fullName ?? 'Member',
        size: 34,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'web_admin':
            await launchUrl(
              Uri.parse('${AppConfig.webBaseUrl}/admin'),
              mode: LaunchMode.externalApplication,
            );
          case 'privacy':
            await launchUrl(
              Uri.parse('${AppConfig.webBaseUrl}/privacy'),
              mode: LaunchMode.inAppWebView,
            );
          case 'terms':
            await launchUrl(
              Uri.parse('${AppConfig.webBaseUrl}/terms'),
              mode: LaunchMode.inAppWebView,
            );
          case 'signout':
            await context.read(backendProvider).signOut();
            if (context.mounted) context.go('/');
          default:
            context.go(value);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: '/profile',
          child: _MenuItem(Icons.person_outline, 'Profile'),
        ),
        const PopupMenuItem(
          value: '/relationships',
          child: _MenuItem(Icons.favorite_outline, 'My relationships'),
        ),
        if ((me?.maritalStatus ?? '') == 'married')
          const PopupMenuItem(
            value: '/household',
            child: _MenuItem(Icons.home_outlined, 'Household'),
          ),
        const PopupMenuItem(
          value: '/conferences',
          child: _MenuItem(Icons.event_outlined, 'Conferences'),
        ),
        const PopupMenuItem(
          value: '/notifications',
          child: _MenuItem(Icons.notifications_outlined, 'Notifications'),
        ),
        const PopupMenuItem(
          value: '/account/security',
          child: _MenuItem(Icons.shield_outlined, 'Account'),
        ),
        if (canConsult)
          const PopupMenuItem(
            value: '/consult',
            child: _MenuItem(Icons.handshake_outlined, 'Consultations'),
          ),
        if (isAdmin)
          const PopupMenuItem(
            value: 'web_admin',
            child: _MenuItem(Icons.admin_panel_settings_outlined,
                'Administration is available on the web'),
          ),
        const PopupMenuItem(
          value: 'privacy',
          child: _MenuItem(Icons.privacy_tip_outlined, 'Privacy notice'),
        ),
        const PopupMenuItem(
          value: 'terms',
          child: _MenuItem(Icons.description_outlined, 'Community terms'),
        ),
        const PopupMenuItem(
          value: 'signout',
          child: _MenuItem(Icons.logout, 'Sign out'),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 19, color: C.plum700),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: C.ink),
            ),
          ),
        ],
      );
}

/// Bronze-gradient "Live now" bar under the header.
class LiveBar extends ConsumerWidget {
  const LiveBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveNowProvider);
    final items = live.valueOrNull ?? const <Map<String, dynamic>>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final first = items.first;
    final more = items.length - 1;
    return Container(
      decoration: const BoxDecoration(gradient: C.liveBar),
      child: InkWell(
        onTap: () => context.go(
            '/conferences/${first['conference_id'] ?? ''}/live/${first['session_id'] ?? first['id']}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live now: ${first['title'] ?? 'A session'}'
                  '${first['conference_title'] != null ? ', ${first['conference_title']}' : ''}'
                  '${more > 0 ? ' and $more more' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  (first['registered'] == true)
                      ? 'Join the live room'
                      : 'Register and join',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: C.crimson600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
