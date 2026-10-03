# Isosha Esosheni — Flutter App

A native **iOS + Android** client for [Isosha Esosheni](https://isosha-esosheni-two.vercel.app), the governed
relationship / courtship / marriage / community platform of **The Revelation Spiritual Home Kingdom**.

> ⚠️ This is **not** a casual-dating app. There is no swiping, no "boosts", no ads and no
> behavioural tracking. Every connection is deliberate, overseen by shepherds and elders,
> and bounded by the platform's covenant rules — which live entirely on the server.

The existing **Next.js + Supabase web platform remains the source of truth**. This app is a second
client: it calls the same Supabase project (Auth, RPC functions, storage, realtime) and never
re-implements business rules. All eligibility checks, scoring, privacy filtering, message limits,
contact-info detection, stage gating and moderation are **server-side**; the app only renders what
the server returns.

---

## 1. Requirements

- Flutter **3.47+** for Android builds (the Android toolchain pins come from the 3.47 template),
  Flutter **3.32+** otherwise, JDK **17+** for Android builds (Dart **3.4+**)
- Android: minSdk 24, compileSdk 36, AGP **9.1.0**, Gradle wrapper **9.3.1**, Kotlin (KGP) **2.4.0**
  — all pinned in-repo (`android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties`)
- iOS: Xcode 15+, run `pod install` inside `ios/` after checkout
- **`pubspec.lock` is committed.** This is an app, so the resolved dependency set is part of the
  build; re-resolving caret ranges is how the `record` plugin family broke the Android build
  (see the dependency-drift note in §9). Commit the lock after any dependency change you have
  built successfully.

## 2. Configuration (compile-time `--dart-define`)

The app reads **only** compile-time defines — there are no runtime config files and no secrets in
source control:

| Define            | Meaning                                              | Example |
|-------------------|------------------------------------------------------|---------|
| `SUPABASE_URL`    | Your Supabase project URL                            | `https://xyzcompany.supabase.co` |
| `SUPABASE_ANON_KEY` | The **anon** (publishable) key                     | `eyJ…` |
| `WEB_BASE_URL`    | Base URL of the web platform (privacy/terms/admin links) | `https://isosha-esosheni-two.vercel.app` |

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=WEB_BASE_URL=https://isosha-esosheni-two.vercel.app
```

If the defines are omitted the app automatically boots against a **built-in fake backend**
(`FakeBackend` in `lib/data/backend/fake_backend.dart`) with synthetic demo personas, so the whole
UI can be exercised offline. Switching between the two is a one-line selection in `lib/main.dart`.

**Never** put a `service_role` key, user tokens or passwords in defines, code or logs. Only the
anon key is ever embedded; session tokens are stored exclusively by `supabase_flutter`'s secure
storage. The app logs no PII.

## 3. Supabase dashboard setup (one-time)

1. **Auth → URL Configuration** — add these redirect URLs so the app's OAuth/recovery flows can
   return via deep link:
   - `isosha://auth-callback`
   - `isosha://login-callback`
   - `https://isosha-esosheni-two.vercel.app/**` (web flows, unchanged)
2. **Storage buckets** (already exist for the web app; the app only reads/writes within them):
   `avatars`, `profile-videos`, `chat-media`, `community-media`, `consultation-files`.
3. **Realtime** — the app subscribes to the same channels the web uses:
   `messages`, `message_reactions`, `conversation_participants`, `notifications`, `conference_chat`.

## 4. Deep links

| Platform | Scheme / link |
|----------|---------------|
| Android  | `isosha://auth-callback`, `isosha://login-callback` (intent filters in `AndroidManifest.xml`) |
| Android  | `https://isosha-esosheni-two.vercel.app/auth-callback` via App Links (autoVerify) |
| iOS      | Custom URL schemes `isosha` + Associated Domains (`applinks:isosha-esosheni-two.vercel.app`) — add in the Runner target's *Signing & Capabilities* before shipping |

Deep links are handled by `app_links` and routed to the backend's `handleAuthDeepLink`, which
completes sign-in/recovery exactly like the web callback.

## 5. Architecture

```
lib/
  core/        config, theme (Teal + Bronze tokens), router + pure redirect logic,
               providers (Riverpod), shared widgets, utils (validators, dates,
               contact detection, media URLs, safe-next, WCAG contrast)
  data/
    models/    hand-written immutable models (json_serializable-free on purpose)
    backend/   Backend interface + SupabaseBackend + FakeBackend
    repositories/  feature repositories — the ONLY code that talks to the backend
  features/    auth, home, discover, members, connections, messages, relationships,
               household, community, conferences, notifications, profile, account, consult
```

Rules that are enforced by construction:

- **UI → Repository → Backend.** Screens never import Supabase. Repositories are exposed via
  Riverpod (`lib/core/repos.dart`).
- **No business logic in Dart.** Stage eligibility, match scoring, privacy filtering, message
  limits, and moderation outcomes come from the server; the app renders them.
- **Same routes as the web** (`go_router`), so a notification's `link` opens the same screen on
  mobile. Redirect logic (auth gating, MFA/AAL2, suspended/deactivated, safe-next) is a pure
  function in `lib/core/router_logic.dart` and is unit-tested.

## 6. Testing & static analysis

```bash
flutter analyze
flutter test
```

Coverage includes:

- **Unit** — validators, age/date helpers (SAST), contact-detail regexes, YouTube/Jitsi URL
  helpers, completion weights, WCAG AA contrast of the palette, pure router-guard logic, safe-next.
- **Widget** — MemberCard variants, CompletionMeter, chat bubble kinds, ReportSheet, gate notices.
- **Repository** — a `RecordingBackend` asserts the **exact RPC function names and parameter
  keys** sent to the server (contract parity with the web platform).

## 7. Design system

Palette (authoritative hex; token code-names kept from the web for continuity):

| Token | Hex | Token | Hex |
|-------|-----|-------|-----|
| royal | `#0F4C5C` | crimson (bronze) | `#9A6B1E` |
| plum-700 | `#0A3441` | crimson-600 | `#7A5214` |
| plum-800 | `#06222B` | crimson-100 | `#F6EBD6` |
| plum-500 | `#3C7A89` | gold (brass) | `#C9A24B` |
| plum-100 | `#E1EEF1` | sage / sage-100 | `#2F7A4B` / `#DFF0E6` |
| plum-50 | `#F1F7F8` | rust / rust-100 | `#A12B2B` / `#F8E4E3` |
| canvas | `#F7F5F0` | line | `#E2DDD2` |
| surface | `#FFFFFF` | ink | `#1D2A2E` |
|  |  | muted | `#5F6B6E` |

Fonts (**bundled as assets**, never fetched at runtime): Cormorant Garamond 600/700 for display,
Figtree 400/500/600/700 for UI. Light theme only; no dark mode. All primary text/background pairs
meet **WCAG AA** (verified by `test/unit/contrast_test.dart`).

Story backgrounds use the backend keys `royal | crimson | gold | night` (sent unchanged); only the
rendered colours are mapped through the palette.

## 8. Store-compliance & privacy notes

- **Apple 5.1.1(v) — account deletion.** Native in-app account deletion is **not yet
  implemented** because the web platform does not expose a deletion RPC. The app instead offers
  *"Request account closure"*, which opens the documented email/web path. Before App Store
  submission, either wire the server-side deletion RPC (web team) or keep the app out of the
  categories that require 5.1.1(v).
- **No trackers.** The app ships with **zero** analytics, ads or third-party tracking SDKs.
- **Screenshot protection (Android).** `FLAG_SECURE` is applied while viewing member profiles
  and messages via a small MethodChannel (`com.trsh.isoshaesosheni/secure`).
- **Membership verification** (ID/baptism checks) remains a **web/admin-only** flow by design;
  the app displays the resulting verified state but never performs it.

## 9. Known gaps

| Gap | Notes |
|-----|-------|
| Push notifications | `PushService` is a deliberate no-op interface (`lib/main.dart`). Implement FCM/APNs when the web platform exposes a device-token endpoint. |
| Account deletion | See store-compliance note above. |
| Administration | Staff see a single *"Administration is available on the web"* row that opens `WEB_BASE_URL/admin` in the system browser. Admin is intentionally not built in mobile. |
| iOS Associated Domains | Must be added in Xcode before release builds. |
| Gradle wrapper | The Android wrapper (`gradlew`, `gradlew.bat`, `gradle-wrapper.jar`) is checked in; no extra setup needed. It downloads Gradle 9.3.1 from `android/gradle/wrapper/gradle-wrapper.properties`. Android Studio rewrites that file when Gradle is set to run from a *specified location* — keep it on *"gradle-wrapper.properties (default)"*. See the troubleshooting note below. |

### Android build failures (Gradle / AGP / Kotlin)

The four version numbers that must stay in agreement are the Gradle wrapper, AGP, KGP (Kotlin)
and the Flutter SDK. They are pinned in-repo as `9.3.1` / `9.1.0` / `2.4.0` — the values the
**Flutter 3.47** Android template ships — and every Flutter release since 3.47 aborts the build
before compiling anything if they are below `Gradle 8.14.0` / `AGP 8.11.1` / `KGP 2.2.20`:

```
Error: Your project's Gradle version (8.11.1) is lower than Flutter's minimum supported
version of 8.14.0. Please upgrade your Gradle version.
```

| Symptom | Cause / fix |
|---------|-------------|
| *"Your project's Gradle version (x) is lower than Flutter's minimum supported version of 8.14.0"* | The Flutter SDK is newer than the in-repo pins. Upgrade the trio to the values the current Flutter template ships (`templateDefaultGradleVersion`, `templateAndroidGradlePluginVersion`, `templateKotlinGradlePluginVersion` in the SDK's `packages/flutter_tools/lib/src/android/gradle_utils.dart`) — for 3.47: Gradle 9.3.1, AGP 9.1.0, KGP 2.4.0. These are exactly the numbers in `android/settings.gradle.kts` + the wrapper properties. |
| *"Minimum supported Gradle version is 9.3.1. Current version is …"* | `gradle-wrapper.properties` was downgraded (usually by Android Studio's *specified location* setting). Restore `distributionUrl` to `gradle-9.3.1-all.zip`. |
| *"Starting AGP 9+, only the new DSL interface will be read"* / *"built-in Kotlin"* messages | `android.newDsl=false` and `android.builtInKotlin=false` in `android/gradle.properties` keep AGP 9 on the legacy DSL + legacy KGP path. They are required until every plugin in the dependency tree has migrated — do not delete them. |
| Build must run on an older Flutter (< 3.47) | Temporarily lower the trio to the last pre-AGP-9 line: Gradle **8.14.3** + AGP **8.13.2** + KGP **2.2.20** or newer (above Flutter 3.47's error floors, so it builds with deprecation warnings instead). |

Also note that Flutter 3.47 applies the Kotlin Gradle Plugin itself to modules that apply AGP
without declaring KGP, so `android/app/build.gradle.kts` intentionally has no
`id("kotlin-android")` — do not add it back, or AGP 9 will fail to apply it.

### Dependency drift: `kernel_snapshot_program failed` on a plugin you don't target

Symptom — the Gradle stage succeeds and the build then dies on a *desktop* platform package while
you are building for Android:

```
../../AppData/Local/Pub/Cache/hosted/pub.dev/record_linux-0.7.2/lib/record_linux.dart:12:7: Error:
The non-abstract class 'RecordLinux' is missing implementations for these members:
 - RecordMethodChannelPlatformInterface.startStream
Target kernel_snapshot_program failed: Exception
```

Cause: `record` is a **federated** plugin — one platform-interface package plus one package per
platform (android / ios / macos / linux / windows / web). Flutter compiles *every* member of the
family into the kernel snapshot, including the desktop ones, even for an Android-only build. If
the family resolves to versions that don't agree with each other, the snapshot fails before any
native code is compiled. `record: ^5.2.0` constrained `record_linux` to `^0.7.x`; the newest 0.7
is 0.7.2 (2024-06-26) and predates the `startStream` / `hasPermission(request:)` members that
`record_platform_interface` 1.4+ requires. So 5.x became unbuildable as soon as 1.6.0 was
published, and there is no fix inside the 5.x range.

Fix:

1. `flutter clean`, delete `pubspec.lock`, `flutter pub get`.
2. Keep the family pinned together — `record: 6.2.1` plus the `dependency_overrides` block in
   `pubspec.yaml`, which freezes every member on a version that accepts
   `record_platform_interface` 1.6.x. Move to `record` 7.x only when the project's Flutter floor
   reaches 3.44 / Dart 3.12 — 7.x needs the whole family on 2.x.
3. Commit `pubspec.lock`.

The same failure shape can hit any federated plugin (`share_plus`, `url_launcher`,
`image_picker`, `webview_flutter`, `just_audio`, …): the named package is one platform
implementation of a family. Move the whole family — never patch around the single package that
fails to compile. Note that CI cannot catch this class of failure: `flutter analyze` and
`flutter test` don't compile federated plugin packages, which is why the committed lock file
matters.

## 10. Assumptions

- The Supabase schema/RPC surface matches the contract documented by the web team; the app calls
  **only** those RPCs (see `test/repositories/rpc_param_names_test.dart` for the full list).
- Brand crest is a **placeholder** (`assets/images/crest.png`), and the iOS launcher/launch
  images are generated placeholder art in the brand palette. Drop the real crest at the same
  filenames when available.
- CI runs `flutter analyze` + `flutter test` on every push/PR (`.github/workflows/ci.yml`) on the
  same Flutter version the Android toolchain is pinned to (3.47.x); it does not build the APK.
- Demo accounts (`*@demo.isosha.invalid`) exist only for manual testing against `FakeBackend` and
  are never shipped as credentials.
- Localization: English (en-ZA) only for v1; copy lives in `lib/core/l10n/strings.dart` with an
  ARB mirror in `lib/l10n/app_en_ZA.arb` for future `gen-l10n`.
- `flutter_svg` was listed in the brief but is omitted: no SVG assets exist (the crest ships as
  PNG), so the dependency would be dead weight.
