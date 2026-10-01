import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/brand_header.dart';

/// The signed-in scaffold: brand header, live bar, banners and the
/// 5-destination bottom navigation.
class MemberShell extends ConsumerWidget {
  const MemberShell({super.key, required this.child});

  final Widget child;

  static int _indexFor(String path) {
    if (path.startsWith('/home')) return 0;
    if (path.startsWith('/discover') || path.startsWith('/members')) return 1;
    if (path.startsWith('/community')) return 2;
    if (path.startsWith('/connections')) return 3;
    return 4; // /messages
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final index = _indexFor(path);
    final session = ref.watch(sessionProvider);
    final matches = ref.watch(matchSummaryProvider).valueOrNull;
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    final received = matches?.interestsReceived ?? 0;

    return Scaffold(
      appBar: const BrandHeader(),
      body: Column(
        children: [
          const LiveBar(),
          if (session.restricted)
            _Banner(
              color: C.crimson100,
              textColor: C.crimson600,
              text: 'Your account is restricted. You can view and edit your '
                  'profile, but some features are limited.',
              linkLabel: 'See why and how to appeal',
              onTap: () => context.go('/account/standing'),
            ),
          if (session.me?.isDemo == true)
            const _Banner(
              color: C.plum100,
              textColor: C.plum700,
              text: 'Development demo account. Not a real TRSH member.',
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: C.surface,
        indicatorColor: C.plum100,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/discover');
            case 2:
              context.go('/community');
            case 3:
              context.go('/connections');
            default:
              context.go('/messages');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: _TopIndicator(icon: Icons.home, label: 'Home'),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon:
                const _TopIndicator(icon: Icons.search, label: 'Discover'),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon:
                _TopIndicator(icon: Icons.group, label: 'Community'),
            label: 'Community',
          ),
          NavigationDestination(
            icon: _Badged(icon: Icons.favorite_outline, dot: received > 0),
            selectedIcon: _TopIndicator(
              icon: Icons.favorite,
              label: 'Matches',
              dot: received > 0,
            ),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: _Badged(icon: Icons.chat_bubble_outline, dot: unread > 0),
            selectedIcon: _TopIndicator(
              icon: Icons.chat_bubble,
              label: 'Chats',
              dot: unread > 0,
            ),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.textColor,
    required this.text,
    this.linkLabel,
    this.onTap,
  });

  final Color color;
  final Color textColor;
  final String text;
  final String? linkLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: TextStyle(fontSize: 12.5, color: textColor)),
          if (linkLabel != null)
            InkWell(
              onTap: onTap,
              child: Text(
                linkLabel!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selected destinations show a 3 px royal indicator above the item.
class _TopIndicator extends StatelessWidget {
  const _TopIndicator({required this.icon, required this.label, this.dot = false});

  final IconData icon;
  final String label;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 3, width: 26, color: C.royal),
        const SizedBox(height: 2),
        _Badged(icon: icon, dot: dot),
      ],
    );
  }
}

class _Badged extends StatelessWidget {
  const _Badged({required this.icon, this.dot = false});
  final IconData icon;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 22),
        if (dot)
          const Positioned(
            right: -3,
            top: -1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: C.crimson,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 8, height: 8),
            ),
          ),
      ],
    );
  }
}
