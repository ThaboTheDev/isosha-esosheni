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

- Flutter **3.22+** (Dart **3.4+**)
- Android: minSdk 24, compileSdk 36, AGP 8.9.1 (bundled wrapper)
- iOS: Xcode 15+, run `pod install` inside `ios/` after checkout

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
| Gradle wrapper jar | Android build uses the wrapper config; run `gradle wrapper` once if the jar is missing on your machine. |

## 10. Assumptions

- The Supabase schema/RPC surface matches the contract documented by the web team; the app calls
  **only** those RPCs (see `test/repositories/rpc_param_names_test.dart` for the full list).
- Brand crest is a **placeholder** (`assets/images/crest.png`). Drop the real crest there — same
  filename — when available.
- Demo accounts (`*@demo.isosha.invalid`) exist only for manual testing against `FakeBackend` and
  are never shipped as credentials.
- Localization: English (en-ZA) only for v1; copy lives in `lib/core/l10n/strings.dart` with an
  ARB mirror in `lib/l10n/app_en_ZA.arb` for future `gen-l10n`.
