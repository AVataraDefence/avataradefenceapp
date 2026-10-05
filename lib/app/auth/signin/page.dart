import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../data/session.dart';
import '../../nav.dart';
import '../auth_shell.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _usernamePattern = RegExp(r'^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$');

/// `/auth/signin` (web `src/app/auth/signin/page.tsx`).
class SignInPage extends StatefulWidget {
  const SignInPage({super.key, this.justRegistered = false});

  /// Shown after a successful sign up (`?registered=1` on the web).
  final bool justRegistered;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String _identifierError = '';
  String _passwordError = '';
  String _serverError = '';

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String _validateIdentifier(String v) {
    if (v.trim().isEmpty) return 'Email or Username is required';
    if (v.contains('@')) return _emailPattern.hasMatch(v) ? '' : 'Enter a valid email address';
    return _usernamePattern.hasMatch(v) ? '' : 'Enter a valid username';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _serverError = '';
      _identifierError = _validateIdentifier(_identifier.text);
      _passwordError = _password.text.isEmpty ? 'Password is required' : '';
    });
    if (_identifierError.isNotEmpty || _passwordError.isNotEmpty) return;

    setState(() => _loading = true);
    final r = await AppSession.instance.signIn(_identifier.text.trim(), _password.text);
    if (!mounted) return;
    if (r.ok) {
      AppNav.reset(context, '/module');
      return;
    }
    setState(() {
      _loading = false;
      if (r.statusCode == 404) {
        _identifierError = r.message;
      } else if (r.statusCode == 401) {
        _passwordError = r.message;
      } else {
        _serverError = r.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AuthShell(
      heroTitle: 'Welcome back',
      heroText: 'Sign in to access your dashboard, manage your account and more.',
      topPrompt: "Don't have an account?",
      topLinkLabel: 'Sign up',
      onTopLink: () => AppNav.replace(context, '/auth/signup'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign in', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Enter your credentials to continue', style: t.bodyMedium?.copyWith(color: context.colors.mutedForeground)),
          const SizedBox(height: 24),
          if (widget.justRegistered) ...[
            const AppAlert(title: 'Account created successfully. Sign in to continue.', variant: AppAlertVariant.success),
            const SizedBox(height: 20),
          ],
          AppInput(
            controller: _identifier,
            label: 'Email / Username',
            hint: 'Email or Username',
            error: _identifierError.isEmpty ? null : _identifierError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _identifierError = ''),
          ),
          const SizedBox(height: 16),
          AppPasswordInput(
            controller: _password,
            label: 'Password',
            hint: 'Password',
            error: _passwordError.isEmpty ? null : _passwordError,
            onChanged: (_) => setState(() => _passwordError = ''),
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(label: 'Forgot password?', variant: AppButtonVariant.ghost, size: AppButtonSize.sm, onPressed: () => AppNav.push(context, '/auth/forgot-password')),
          ),
          if (_serverError.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_serverError, style: t.bodySmall?.copyWith(color: context.colors.destructive))),
          const SizedBox(height: 4),
          AppButton(label: _loading ? 'Signing in…' : 'Sign in', trailingIcon: LucideIcons.arrowRight, expand: true, loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
