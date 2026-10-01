import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/deep_link_state.dart';
import 'package:isosha_esosheni/core/providers.dart';
import 'package:isosha_esosheni/core/router_logic.dart';
import 'package:isosha_esosheni/data/models/profile.dart';

void main() {
  const signedOut = SessionSnapshot(loaded: true);
  const signedIn = SessionSnapshot(loaded: true, signedIn: true);
  const mfa = SessionSnapshot(loaded: true, signedIn: true, aal2Required: true);
  final suspended = SessionSnapshot(
    loaded: true,
    signedIn: true,
    me: const OwnProfile(id: 'u', accountStatus: 'suspended'),
  );
  final restricted = SessionSnapshot(
    loaded: true,
    signedIn: true,
    me: const OwnProfile(id: 'u', accountStatus: 'restricted'),
  );

  test('signed-out member hitting a protected path is sent to login with next',
      () {
    expect(
      computeRedirect(session: signedOut, path: '/home'),
      '/login?next=%2Fhome',
    );
    expect(computeRedirect(session: signedOut, path: '/login'), isNull);
    expect(computeRedirect(session: signedOut, path: '/'), isNull);
  });

  test('signed-in member on auth pages goes home', () {
    expect(computeRedirect(session: signedIn, path: '/login'), '/home');
    expect(computeRedirect(session: signedIn, path: '/register'), '/home');
    expect(computeRedirect(session: signedIn, path: '/'), '/home');
    expect(computeRedirect(session: signedIn, path: '/home'), isNull);
  });

  test('MFA required redirects every protected route', () {
    expect(computeRedirect(session: mfa, path: '/home'), '/login/mfa');
    expect(computeRedirect(session: mfa, path: '/messages/c-1'), '/login/mfa');
    expect(computeRedirect(session: mfa, path: '/login/mfa'), isNull);
  });

  test('suspended accounts are fenced to the suspended screen', () {
    expect(
      computeRedirect(session: suspended, path: '/home'),
      '/account/suspended',
    );
    expect(
      computeRedirect(session: suspended, path: '/account/suspended'),
      isNull,
    );
  });

  test('restricted accounts are allowed through (banner is in-shell)', () {
    expect(computeRedirect(session: restricted, path: '/home'), isNull);
    expect(restricted.restricted, isTrue);
  });

  test('recovery deep link lands on reset password once', () {
    DeepLinkState.recoveryPending = true;
    expect(
      computeRedirect(session: signedIn, path: '/home'),
      '/reset-password',
    );
    computeRedirect(session: signedIn, path: '/reset-password');
    expect(DeepLinkState.recoveryPending, isFalse);
  });

  test('confirmation deep link lands on profile edit', () {
    DeepLinkState.justConfirmed = true;
    expect(
      computeRedirect(session: signedIn, path: '/home'),
      '/profile/edit',
    );
    expect(DeepLinkState.justConfirmed, isFalse);
  });
}
