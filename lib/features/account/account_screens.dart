import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/repos.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/loading.dart';
import '../../core/widgets/panel.dart';
import '../../data/models/safety.dart';

class MfaFactorLike {
  const MfaFactorLike(this.id, this.status, this.staff);
  final String id;
  final String status;
  final bool staff;
  bool get verified => status == 'verified';
}

/// Security: TOTP enrolment / removal, password change, closure request.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  List<MfaFactorLike> _factors = [];
  bool _staff = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final backend = context.read(backendProvider);
    final factors = await backend.listMfaFactors();
    final perms =
        await context.read(accountRepoProvider).permissions().catchError(
            (_) => <String>[]);
    if (!mounted) return;
    setState(() {
      _factors = factors.map((f) => MfaFactorLike(f.id, f.status, false)).toList();
      _staff = perms.contains('staff.access') ||
          perms.contains('consultations.handle') ||
          perms.contains('consultations.super');
      _loaded = true;
    });
  }

  Future<void> _enroll() async {
    final backend = context.read(backendProvider);
    try {
      final e = await backend.enrollTotp();
      if (!mounted) return;
      final code = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Set up two-factor authentication',
              style: T.headline.copyWith(fontSize: 21)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: e.uri,
                  size: 170,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 10),
                Text('Or enter this key manually:', style: T.small),
                SelectableText(e.secret,
                    style: T.bodyStrong.copyWith(fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  controller: code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                      labelText: '6-digit code', filled: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            PrimaryButton(
                label: 'Verify', onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        ),
      );
      if (ok != true) return;
      final out = await backend.verifyMfa(e.factorId, code.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(out.ok
                ? 'Two-factor authentication is on.'
                : 'That code is not valid. Check the time on your phone and '
                    'try again.')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Security'),
      body: !_loaded
          ? const LoadingPanel()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Two-factor authentication',
                          style: T.headline.copyWith(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        _factors.any((f) => f.verified)
                            ? 'Two-factor authentication is on.'
                            : 'Add an authenticator app to keep your account '
                                'safe.',
                        style: T.body.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      if (_factors.any((f) => f.verified))
                        QuietButton(
                          label: 'Turn off',
                          onPressed: () async {
                            if (_staff) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Staff accounts must keep two-factor authentication on.')));
                              return;
                            }
                            try {
                              await context
                                  .read(backendProvider)
                                  .unenrollMfa(_factors
                                      .firstWhere((f) => f.verified)
                                      .id);
                              _load();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(friendlyError(e))));
                              }
                            }
                          },
                        )
                      else
                        GoldButton(label: 'Set up', onPressed: _enroll),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Password',
                          style: T.headline.copyWith(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        'Use the reset flow to choose a new password at any '
                        'time.',
                        style: T.body.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      QuietButton(
                        label: 'Change password',
                        onPressed: () async {
                          final me = context.read(sessionProvider).me;
                          try {
                            await context
                                .read(backendProvider)
                                .requestPasswordReset(me?.email ?? '');
                          } catch (_) {}
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'If an account exists for that address, a reset link is on its way.')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account closure',
                          style: T.headline.copyWith(fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(
                        'Account closure is handled by a membership '
                        'administrator. This button opens your email app '
                        'with a closure request.',
                        style: T.body.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      QuietButton(
                        label: 'Request account closure',
                        onPressed: () async {
                          final uri = Uri(
                            scheme: 'mailto',
                            path: 'membership@isosha.invalid',
                            queryParameters: {
                              'subject': 'Account closure request',
                              'body': 'Please close my Isosha Esosheni '
                                  'account.',
                            },
                          );
                          try {
                            await launchUrl(uri);
                          } catch (_) {}
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
  }
}

/// Blocked members list.
class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  List<BlockedRow>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await context.read(discoveryRepoProvider).blocked();
      if (mounted) {
        setState(() => _rows = [
              for (final r in rows) BlockedRow(r.id, r.displayName),
            ]);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Blocked members'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _rows == null
              ? const LoadingPanel()
              : _rows!.isEmpty
                  ? const EmptyState(
                      message: 'You have not blocked anyone.',
                      icon: Icons.block,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Blocking hides each of you from the other '
                          'entirely.',
                          style: T.small,
                        ),
                        const SizedBox(height: 10),
                        for (final r in _rows!)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: C.surface,
                              border: Border.all(color: C.line),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(r.name,
                                      style: T.bodyStrong
                                          .copyWith(fontSize: 14)),
                                ),
                                QuietButton(
                                  label: 'Unblock',
                                  onPressed: () async {
                                    try {
                                      await context
                                          .read(discoveryRepoProvider)
                                          .unblock(r.id);
                                      _load();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    friendlyError(e))));
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class BlockedRow {
  const BlockedRow(this.id, this.name);
  final String id;
  final String name;
}

/// Standing and appeals.
class StandingScreen extends StatefulWidget {
  const StandingScreen({super.key});

  @override
  State<StandingScreen> createState() => _StandingScreenState();
}

class _StandingScreenState extends State<StandingScreen> {
  Standing? _standing;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await context.read(safetyRepoProvider).standing();
      if (mounted) setState(() => _standing = s);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'Your standing'),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _standing == null
              ? const LoadingPanel()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account status',
                              style: T.headline.copyWith(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            _standing!.accountStatus,
                            style: T.bodyStrong.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_standing!.activeStrikes} active '
                            '${_standing!.activeStrikes == 1 ? 'strike' : 'strikes'} '
                            'in the last ${_standing!.strikeWindowDays} days. '
                            '${_standing!.strikesToRestrict} strikes restrict; '
                            '${_standing!.strikesToSuspend} suspend.',
                            style: T.small,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_standing!.sanctions.isEmpty)
                      const EmptyState(
                        message: 'Your record is clear.',
                        icon: Icons.verified_outlined,
                      ),
                    for (final s in _standing!.sanctions) _sanction(s),
                  ],
                ),
    );
  }

  Widget _sanction(Sanction s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.kind[0].toUpperCase() + s.kind.substring(1),
                    style: T.headline.copyWith(fontSize: 18),
                  ),
                ),
                ChipLite(s.statusLabel),
              ],
            ),
            const SizedBox(height: 4),
            Text(s.kindMeaning, style: T.small),
            if (s.reason != null)
              Text('Reason: ${s.reason}',
                  style: T.body.copyWith(fontSize: 14)),
            if (s.startsAt != null)
              Text('From ${Dates.fmt(DateTime.parse(s.startsAt!))}'
                  '${s.endsAt != null ? ' until ${Dates.fmt(DateTime.parse(s.endsAt!))}' : ''}',
                  style: T.small.copyWith(fontSize: 12)),
            if (s.canAppeal) ...[
              const SizedBox(height: 8),
              QuietButton(
                label: 'Appeal',
                onPressed: () => _appeal(s),
              ),
            ] else if (s.hasAppeal)
              Text('An appeal has been submitted.',
                  style: T.small.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _appeal(Sanction s) async {
    final statement = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Appeal this ${s.kind}',
            style: T.headline.copyWith(fontSize: 21)),
        content: TextField(
          controller: statement,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
              labelText: 'Your statement', filled: true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          PrimaryButton(
              label: 'Submit appeal',
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context
          .read(safetyRepoProvider)
          .submitAppeal(s.id, statement.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appeal received.')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }
}

class ChipLite extends StatelessWidget {
  const ChipLite(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: C.plum100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11.5, color: C.plum700)),
    );
  }
}

/// My information export (POPIA right of access).
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false, title: 'My information'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Download your information',
                    style: T.headline.copyWith(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  'You can download your own information (POPIA right of '
                  'access). Messages and content written by others are not '
                  'included.',
                  style: T.body.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Export my information',
                  onPressed: () async {
                    try {
                      final data = await context
                          .read(accountRepoProvider)
                          .exportMyData();
                      final dir = Directory.systemTemp;
                      final file = File(
                          '${dir.path}/isosha-esosheni-my-information.json');
                      await file.writeAsString(
                          const JsonEncoder.withIndent('  ').convert(data));
                      await Share.shareXFiles([XFile(file.path)],
                          subject: 'My Isosha Esosheni information');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(friendlyError(e))));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Suspended / deactivated screen.
class SuspendedScreen extends ConsumerWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final back = !session.suspended;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/crest.png',
                      width: 84, height: 84, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                Text(
                  back ? 'Welcome back' : 'Your account is not active',
                  style: T.display,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  back
                      ? 'Your suspension has ended. Thank you for your '
                          'patience.'
                      : (session.accountStatus == 'deactivated'
                          ? 'Your account has been deactivated. If you '
                              'believe this is a mistake, please contact a '
                              'membership administrator.'
                          : 'Your account is suspended. The reason is shown '
                              'below. If you believe the decision is wrong, '
                              'you may appeal it here.'),
                  style: T.body,
                  textAlign: TextAlign.center,
                ),
                if (back) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Continue',
                    onPressed: () => context.go('/home'),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  const _SuspendedSanctions(),
                  const SizedBox(height: 16),
                  QuietButton(
                    label: 'Sign out',
                    onPressed: () async {
                      await context.read(backendProvider).signOut();
                      if (context.mounted) context.go('/');
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuspendedSanctions extends StatelessWidget {
  const _SuspendedSanctions();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Standing>(
      future: context.read(safetyRepoProvider).standing(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        final active = snap.data!.sanctions
            .where((s) => s.status == 'active')
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final s in active)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.rust100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.kind, style: T.bodyStrong.copyWith(fontSize: 14)),
                    if (s.reason != null)
                      Text(s.reason!,
                          style: T.body.copyWith(fontSize: 13)),
                    if (s.canAppeal)
                      TextButton(
                        onPressed: () => context.go('/account/standing'),
                        child: const Text('Appeal'),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
