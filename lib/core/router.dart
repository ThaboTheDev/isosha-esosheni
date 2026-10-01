import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../features/account/account_screens.dart';
import '../features/auth/login_screens.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/community/community_screen.dart';
import '../features/community/post_detail_screen.dart';
import '../features/conferences/conferences_screens.dart';
import '../features/connections/connections_screen.dart';
import '../features/consult/consult_screens.dart';
import '../features/discover/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/household/household_screen.dart';
import '../features/members/member_profile_screen.dart';
import '../features/messages/chat_room_screen.dart';
import '../features/messages/messages_list_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/profile/profile_more_screens.dart';
import '../features/relationships/relationships_screen.dart';
import '../features/shell/member_shell.dart';
import 'config.dart';
import 'providers.dart';
import 'router_logic.dart';
import 'theme/colors.dart';

class RouterRefresher extends ChangeNotifier {
  RouterRefresher(Ref ref) {
    ref.listen(sessionProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresher = RouterRefresher(ref);

  String? redirect(BuildContext context, GoRouterState state) {
    final session = ref.read(sessionProvider);
    return computeRedirect(session: session, path: state.uri.path);
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresher,
    redirect: redirect,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) =>
            LoginScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(path: '/login/mfa', builder: (_, __) => const MfaScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/check-email', builder: (_, __) => const CheckEmailScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const WebPage('/privacy')),
      GoRoute(path: '/terms', builder: (_, __) => const WebPage('/terms')),
      GoRoute(
        path: '/account/suspended',
        builder: (_, __) => const SuspendedScreen(),
      ),
      GoRoute(
        path: '/messages/match/:matchId',
        builder: (_, state) => MatchRedirectScreen(
            matchId: state.pathParameters['matchId'] ?? ''),
      ),
      ShellRoute(
        builder: (_, __, child) => MemberShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/discover',
              builder: (_, __) => const DiscoverScreen()),
          GoRoute(
              path: '/community',
              builder: (_, __) => const CommunityScreen()),
          GoRoute(
            path: '/connections',
            builder: (_, state) =>
                ConnectionsScreen(initialTab: state.uri.queryParameters['tab']),
          ),
          GoRoute(
              path: '/messages',
              builder: (_, __) => const MessagesListScreen()),
        ],
      ),
      GoRoute(
        path: '/discover/search',
        builder: (_, __) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/discover/households',
        builder: (_, __) => const DiscoverScreen(),
      ),
      GoRoute(
        path: '/members/:id',
        builder: (_, state) =>
            MemberProfileScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (_, state) => ChatRoomScreen(
            conversationId: state.pathParameters['conversationId'] ?? ''),
      ),
      GoRoute(
          path: '/relationships',
          builder: (_, __) => const RelationshipsScreen()),
      GoRoute(path: '/household', builder: (_, __) => const HouseholdScreen()),
      GoRoute(
        path: '/community/p/:id',
        builder: (_, state) =>
            PostDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
          path: '/conferences',
          builder: (_, __) => const ConferencesScreen()),
      GoRoute(
        path: '/conferences/speaking',
        builder: (_, __) => const SpeakingScreen(),
      ),
      GoRoute(
        path: '/conferences/:id',
        builder: (_, state) =>
            ConferenceDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/conferences/:id/live/:session',
        builder: (_, state) => LiveRoomScreen(
            sessionId: state.pathParameters['session'] ?? ''),
      ),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileHubScreen()),
      GoRoute(
          path: '/profile/edit',
          builder: (_, __) => const ProfileEditScreen()),
      GoRoute(
          path: '/profile/media',
          builder: (_, __) => const ProfileMediaScreen()),
      GoRoute(
          path: '/profile/preferences',
          builder: (_, __) => const PreferencesScreen()),
      GoRoute(
          path: '/profile/privacy',
          builder: (_, __) => const PrivacyScreen()),
      GoRoute(
          path: '/account/security',
          builder: (_, __) => const SecurityScreen()),
      GoRoute(
          path: '/account/blocked', builder: (_, __) => const BlockedScreen()),
      GoRoute(
          path: '/account/standing',
          builder: (_, __) => const StandingScreen()),
      GoRoute(path: '/account/data', builder: (_, __) => const DataScreen()),
      GoRoute(path: '/consult', builder: (_, __) => const ConsultDashboardScreen()),
      GoRoute(
        path: '/consult/households',
        builder: (_, __) => const ConsultHouseholdsScreen(),
      ),
      GoRoute(
        path: '/consult/:id',
        builder: (_, state) =>
            ConsultCaseScreen(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

/// In-app browser view for the web privacy/terms pages.
class WebPage extends StatefulWidget {
  const WebPage(this.path, {super.key});
  final String path;

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  late final WebViewController _ctl = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unconditional)
    ..loadRequest(Uri.parse(AppConfig.webBaseUrl + widget.path));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path == '/privacy' ? 'Privacy notice' : 'Community terms'),
        backgroundColor: C.plum800,
      ),
      body: WebViewWidget(controller: _ctl),
    );
  }
}
