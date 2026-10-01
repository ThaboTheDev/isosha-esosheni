import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'core/deep_link_state.dart';
import 'core/providers.dart';
import 'core/utils/dates.dart';
import 'data/backend/backend.dart';
import 'data/backend/fake_backend.dart';
import 'data/backend/supabase_backend.dart';

/// Extension point for push notifications: the backend only writes
/// `notifications` rows today. A no-op [PushService] keeps the seam; wire
/// FCM/APNs plus a Supabase database webhook (or Edge Function) on
/// `notifications` inserts to it later (see README).
abstract class PushService {
  Future<void> init();
  Future<void> onNotificationRow(Map<String, dynamic> row);
}

class NoopPushService implements PushService {
  @override
  Future<void> init() async {}

  @override
  Future<void> onNotificationRow(Map<String, dynamic> row) async {}
}

final pushServiceProvider = Provider<PushService>((ref) => NoopPushService());

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(Dates.sastLocale);

  Backend backend;
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    backend = SupabaseBackend(Supabase.instance.client);
  } else {
    backend = FakeBackend();
  }

  runApp(
    ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(backend),
      ],
      child: const IsoshaApp(),
    ),
  );

  unawaited(_handleDeepLinks(backend));
}

/// isosha://auth-callback for email confirmation and password recovery.
Future<void> _handleDeepLinks(Backend backend) async {
  final links = AppLinks();

  Future<void> handle(Uri uri) async {
    if (uri.scheme != 'isosha') return;
    if (uri.host != 'auth-callback' && uri.host != 'login-callback') return;
    final recovery = uri.fragment.contains('type=recovery') ||
        uri.queryParameters['type'] == 'recovery';
    if (recovery) {
      DeepLinkState.recoveryPending = true;
    }
    final out = await backend.handleAuthDeepLink(uri);
    if (!recovery && (out?.ok ?? false)) {
      DeepLinkState.justConfirmed = true;
    }
    // The router's redirect reacts to the resulting session change:
    // recovery lands on /reset-password, confirmation on /profile/edit.
  }

  final initial = await links.getInitialLink().catchError((_) => null);
  if (initial != null) await handle(initial);
  links.uriLinkStream.listen(handle);
}
