import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/safe_next.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/brand_header.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/panel.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandHeader(showMenu: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: T.display),
                  const SizedBox(height: 16),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.next});
  final String? next;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final backend = context.read(backendProvider);
    final out =
        await backend.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (!out.ok) {
      setState(() {
        _busy = false;
        switch (out.code) {
          case 'email_not_confirmed':
            _error = 'Confirm your email address first. Check your inbox '
                'for the link.';
          case 'rate_limited':
            _error = 'Too many attempts. Wait a few minutes and try again.';
          default:
            _error = 'The email or password is incorrect.';
        }
      });
      return;
    }
    await context.read(sessionProvider.notifier).reload();
    if (!mounted) return;
    context.go(safeNext(widget.next));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Sign in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
                labelText: 'Email address', filled: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration:
                const InputDecoration(labelText: 'Password', filled: true),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: C.rust100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: C.rust, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Sign in',
            busy: _busy,
            busyLabel: 'Signing in',
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/forgot-password'),
            child: Text('Forgot your password?',
                style: T.bodyStrong.copyWith(color: C.royal, fontSize: 14)),
          ),
          TextButton(
            onPressed: () => context.go('/register'),
            child: Text('Create an account',
                style: T.bodyStrong.copyWith(color: C.royal, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class MfaScreen extends StatefulWidget {
  const MfaScreen({super.key});

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final backend = context.read(backendProvider);
    final factors = await backend.listMfaFactors();
    final verified = factors.where((f) => f.verified).toList();
    if (verified.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final out = await backend.verifyMfa(verified.first.id, _code.text.trim());
    if (!mounted) return;
    if (!out.ok) {
      setState(() {
        _busy = false;
        _error = 'That code is not valid. Check the time on your phone and '
            'try again.';
      });
      return;
    }
    await context.read(sessionProvider.notifier).reload();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Two-factor check',
      child: Column(
        children: [
          Text(
            'Enter the 6-digit code from your authenticator app.',
            style: T.body.copyWith(color: C.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                fontFamily: T.headingFamily,
                fontWeight: FontWeight.w700,
                fontSize: 30,
                letterSpacing: 8,
                color: C.plum700,
              ),
              decoration: const InputDecoration(
                counterText: '',
                filled: true,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: C.rust, fontSize: 13),
                textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: 'Verify', busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Check your email',
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We have sent you a confirmation link. Open it on this '
              'device to continue to your profile.',
              style: T.body,
            ),
            const SizedBox(height: 12),
            Text(
              'The link opens the app and takes you straight to your '
              'profile page.',
              style: T.small,
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await context
          .read(backendProvider)
          .requestPasswordReset(_email.text.trim());
    } catch (_) {
      // Always show the same neutral message.
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Forgot password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration:
                const InputDecoration(labelText: 'Email address', filled: true),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Send reset link',
            busy: _busy,
            onPressed: _sent ? null : _submit,
          ),
          if (_sent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.sage100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'If an account exists for that address, a reset link is on '
                'its way.',
                style: const TextStyle(color: C.sage, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _pwError;

  @override
  void dispose() {
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pwErr = Validators.password(_pw.text);
    final cErr = Validators.confirm(_pw.text, _confirm.text);
    setState(() {
      _pwError = pwErr ?? cErr;
    });
    if (_pwError != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final out = await context.read(backendProvider).updatePassword(_pw.text);
    if (!mounted) return;
    if (!out.ok) {
      setState(() {
        _busy = false;
        _error = 'The reset link has expired. Request a new one.';
      });
      return;
    }
    await context.read(sessionProvider.notifier).reload();
    if (!mounted) return;
    context.go('/home');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Your password was updated.'),
      backgroundColor: C.sage,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choose a new password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(
            label: 'New password',
            error: _pwError,
            child: TextField(
              controller: _pw,
              obscureText: true,
              decoration: const InputDecoration(filled: true),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Confirm password', filled: true),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: C.rust, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
              label: 'Update password', busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
