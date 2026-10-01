/// Compile-time configuration. Nothing sensitive lives in the repo:
/// the Supabase URL / anon key arrive via --dart-define.
///
/// ```
/// flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co \
///             --dart-define=SUPABASE_ANON_KEY=<anon key> \
///             --dart-define=WEB_BASE_URL=https://isosha-esosheni-two.vercel.app
/// ```
library;

class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://isosha-esosheni-two.vercel.app',
  );

  /// Deep link used for email confirmation and password recovery.
  static const String authRedirectUri = 'isosha://auth-callback';

  /// When the Supabase defines are absent the app runs against the
  /// in-memory demo backend so the UI can be developed and demoed.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
