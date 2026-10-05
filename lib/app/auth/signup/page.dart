import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../data/session.dart';
import '../../nav.dart';
import '../auth_shell.dart';

/// `/auth/signup` (web `src/app/auth/signup/page.tsx`).
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  bool _submitted = false;
  bool _loading = false;
  String _serverError = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (_email.text.isEmpty || _password.text.isEmpty || _username.text.isEmpty) return;
    setState(() => _loading = true);
    final r = await AppSession.instance.signUp(email: _email.text.trim(), password: _password.text, username: _username.text.trim());
    if (!mounted) return;
    if (r.ok) {
      Navigator.of(context).pushReplacementNamed('/auth/signin', arguments: {'registered': true});
      return;
    }
    setState(() {
      _loading = false;
      _serverError = r.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return AuthShell(
      heroTitle: 'Create your free account',
      heroText: 'Explore core features built for individuals and organizations.',
      topPrompt: 'Already have an account?',
      topLinkLabel: 'Sign in',
      onTopLink: () => AppNav.replace(context, '/auth/signin'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign up for AvataraDefence', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Create your account to get started', style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
          const SizedBox(height: 24),
          AppInput(
            controller: _email,
            label: 'Email',
            hint: 'Email',
            required: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            error: _submitted && _email.text.isEmpty ? 'Email is required' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          AppPasswordInput(
            controller: _password,
            label: 'Password',
            hint: 'Password',
            required: true,
            error: _submitted && _password.text.isEmpty ? 'Password is required' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Text('Password should be at least 15 characters OR at least 8 characters including a number and a lowercase letter.', style: t.bodySmall),
          const SizedBox(height: 16),
          AppInput(
            controller: _username,
            label: 'Username',
            hint: 'Username',
            required: true,
            textInputAction: TextInputAction.done,
            error: _submitted && _username.text.isEmpty ? 'Username is required' : null,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 4),
          Text('Username may only contain alphanumeric characters or single hyphens, and cannot begin or end with a hyphen.', style: t.bodySmall),
          if (_serverError.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_serverError, style: t.bodySmall?.copyWith(color: c.destructive))),
          const SizedBox(height: 20),
          AppButton(label: _loading ? 'Creating account…' : 'Create account', trailingIcon: LucideIcons.arrowRight, expand: true, loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
