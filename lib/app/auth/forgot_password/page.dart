import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/core.dart';
import '../../nav.dart';
import '../auth_shell.dart';

/// `/auth/forgot-password` (web `src/app/auth/forgot-password/page.tsx`).
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _submitted = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (_email.text.isEmpty) return;
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return AuthShell(
      heroTitle: 'Forgot your password?',
      heroText: "No worries — enter your email and we'll send you a reset link right away.",
      topPrompt: 'Remember your password?',
      topLinkLabel: 'Sign in',
      onTopLink: () => AppNav.back(context, '/auth/signin'),
      child: _sent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: c.isDark ? const Color(0xFF052E16) : TwColors.green50, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.mailCheck, size: 32, color: Color(0xFF16A34A)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Check your email', textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'We sent a password reset link to ',
                    children: [TextSpan(text: _email.text, style: TextStyle(fontWeight: FontWeight.w600, color: c.foreground))],
                  ),
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: c.mutedForeground),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text("Didn't receive the email? ", style: t.bodySmall),
                    GestureDetector(
                      onTap: () => setState(() {
                        _sent = false;
                        _submitted = false;
                      }),
                      child: Text('Try again', style: t.bodySmall?.copyWith(color: c.foreground, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Back to sign in', icon: LucideIcons.arrowLeft, variant: AppButtonVariant.outline, expand: true, onPressed: () => AppNav.back(context, '/auth/signin')),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reset your password', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text("Enter the email address linked to your account and we'll send you a reset link.", style: t.bodyMedium?.copyWith(color: c.mutedForeground)),
                const SizedBox(height: 24),
                AppInput(
                  controller: _email,
                  label: 'Email address',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  error: _submitted && _email.text.isEmpty ? 'Email is required' : null,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                AppButton(label: 'Send reset link', expand: true, onPressed: _submit),
                const SizedBox(height: 12),
                AppButton(label: 'Back to sign in', icon: LucideIcons.arrowLeft, variant: AppButtonVariant.ghost, expand: true, onPressed: () => AppNav.back(context, '/auth/signin')),
              ],
            ),
    );
  }
}
