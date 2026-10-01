import '../core/deep_link_state.dart';
import 'providers.dart';

const Set<String> publicPaths = {
  '/',
  '/login',
  '/register',
  '/check-email',
  '/forgot-password',
  '/reset-password',
  '/privacy',
  '/terms',
};

/// The single redirect function re-evaluated on auth state changes.
/// Kept pure so it is unit-testable.
String? computeRedirect({
  required SessionSnapshot session,
  required String path,
}) {
  if (!session.loaded) return null;
  final signedIn = session.signedIn;

  // 1. Signed-out members only see public pages.
  if (!signedIn && !publicPaths.contains(path)) {
    return '/login?next=${Uri.encodeComponent(path)}';
  }
  // 2. Signed-in members skip the auth pages.
  if (signedIn && (path == '/' || path == '/login' || path == '/register')) {
    return '/home';
  }
  // 3. MFA challenge applies to every protected route.
  if (signedIn && session.aal2Required && path != '/login/mfa') {
    return '/login/mfa';
  }
  if (signedIn && !session.aal2Required && path == '/login/mfa') {
    return '/home';
  }
  // 4. Suspended / deactivated accounts.
  if (signedIn && session.suspended && path != '/account/suspended') {
    return '/account/suspended';
  }
  // Deep-link landings: recovery -> reset, confirmation -> profile edit.
  if (signedIn && !session.suspended && !session.aal2Required) {
    if (DeepLinkState.recoveryPending && path != '/reset-password') {
      return '/reset-password';
    }
    if (path == '/reset-password') {
      DeepLinkState.recoveryPending = false;
    }
    if (DeepLinkState.justConfirmed && path == '/home') {
      DeepLinkState.justConfirmed = false;
      return '/profile/edit';
    }
  }
  // 5/6. Restricted and demo accounts are allowed through; their banners
  // are rendered by the shell.
  return null;
}
