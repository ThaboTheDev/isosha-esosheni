import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import 'login_screens.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullName = TextEditingController();
  final _preferredName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _popia = false;
  bool _terms = false;
  bool _busy = false;
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _fullName.dispose();
    _preferredName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final max = DateTime.now().subtract(const Duration(days: 18 * 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: max.subtract(const Duration(days: 25 * 365)),
      firstDate: DateTime(1900),
      lastDate: max,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    final errs = <String, String?>{
      'fullName': Validators.fullName(_fullName.text),
      'preferredName': Validators.preferredName(_preferredName.text),
      'gender': _gender == null ? 'Select your gender.' : null,
      'dob': Validators.dateOfBirth(_dob, DateTime.now()),
      'email': Validators.email(_email.text),
      'password': Validators.password(_password.text),
      'confirm': Validators.confirm(_password.text, _confirm.text),
      'popia': _popia ? null : 'Consent to the privacy notice is required.',
      'terms': _terms ? null : 'Acceptance of the community terms is required.',
    };
    setState(() => _errors.addAll(errs));
    if (errs.values.any((v) => v != null)) return;

    setState(() {
      _busy = true;
    });
    final out = await context.read(backendProvider).signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {
            'full_name': _fullName.text.trim(),
            'preferred_name': _preferredName.text.trim(),
            'gender': _gender,
            'date_of_birth': Validators2.dob(_dob!),
            'popia_consent': true,
            'terms_accepted': true,
          },
        );
    if (!mounted) return;
    if (!out.ok) {
      setState(() {
        _busy = false;
        switch (out.code) {
          case 'rate_limited':
            _errors['password'] =
                'Too many attempts. Wait a few minutes and try again.';
          case 'password':
            _errors['password'] = out.message ?? 'Check your password.';
          default:
            _errors['confirm'] = 'Registration could not be completed. '
                'Check your details and try again.';
        }
      });
      return;
    }
    context.go('/check-email');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(
            label: 'Full name',
            error: _errors['fullName'],
            child: TextField(
              controller: _fullName,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(filled: true),
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Preferred name (optional)',
            hint: 'The name other members see first.',
            error: _errors['preferredName'],
            child: TextField(
              controller: _preferredName,
              decoration: const InputDecoration(filled: true),
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Gender',
            error: _errors['gender'],
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'female', label: Text('Female')),
                ButtonSegment(value: 'male', label: Text('Male')),
              ],
              selected: {_gender ?? ''},
              onSelectionChanged: (v) =>
                  setState(() => _gender = v.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: C.plum100,
                selectedForegroundColor: C.plum700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Date of birth',
            error: _errors['dob'],
            child: InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: const InputDecoration(filled: true),
                child: Text(
                  _dob == null
                      ? 'Select your date of birth'
                      : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Email',
            error: _errors['email'],
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(filled: true),
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Password',
            hint: 'At least 10 characters, with an uppercase letter, a '
                'lowercase letter and a number.',
            error: _errors['password'],
            child: TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(filled: true),
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Confirm password',
            error: _errors['confirm'],
            child: TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(filled: true),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _popia,
            onChanged: (v) => setState(() => _popia = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('I consent to the ', style: TextStyle(fontSize: 14)),
                InkWell(
                  onTap: () => launchUrl(
                      Uri.parse('${AppConfig.webBaseUrl}/privacy'),
                      mode: LaunchMode.inAppWebView),
                  child: Text(
                    'privacy notice',
                    style: T.bodyStrong.copyWith(
                        color: C.royal, fontSize: 14,
                        decoration: TextDecoration.underline),
                  ),
                ),
                const Text(' (POPIA).', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          if (_errors['popia'] != null)
            Text(_errors['popia']!,
                style: const TextStyle(color: C.rust, fontSize: 13)),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('I accept the ', style: TextStyle(fontSize: 14)),
                InkWell(
                  onTap: () => launchUrl(
                      Uri.parse('${AppConfig.webBaseUrl}/terms'),
                      mode: LaunchMode.inAppWebView),
                  child: Text(
                    'community terms',
                    style: T.bodyStrong.copyWith(
                        color: C.royal, fontSize: 14,
                        decoration: TextDecoration.underline),
                  ),
                ),
                const Text('.', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          if (_errors['terms'] != null)
            Text(_errors['terms']!,
                style: const TextStyle(color: C.rust, fontSize: 13)),
          const SizedBox(height: 16),
          GoldButton(
            label: 'Create account',
            busy: _busy,
            busyLabel: 'Creating account',
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Already have an account? Sign in',
                style: T.bodyStrong.copyWith(color: C.royal, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class Validators2 {
  static String dob(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
