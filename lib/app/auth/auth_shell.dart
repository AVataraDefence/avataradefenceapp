import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/core.dart';

/// Layout shared by Sign in / Sign up / Forgot password (the web's split screen):
/// dark hero panel on the left (wide screens only) and the form on the right.
class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.heroTitle, required this.heroText, required this.topPrompt, required this.topLinkLabel, required this.onTopLink, required this.child});

  final String heroTitle;
  final String heroText;
  final String topPrompt;
  final String topLinkLabel;
  final VoidCallback onTopLink;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final form = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              if (!wide) Text('Avatara Defence', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              // On a phone the prompt is dropped so the link stays on one line.
              if (wide) Text('$topPrompt ', style: t.bodySmall),
              InkWell(
                onTap: onTopLink,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(topLinkLabel, style: t.bodyMedium?.copyWith(color: c.foreground, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 15, color: c.foreground),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(alignment: Alignment.topCenter, child:
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 384), child: child),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: c.isDark ? const Color(0xFF09090B) : Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(child: _Hero(title: heroTitle, text: heroText)),
                  Expanded(child: form),
                ],
              )
            : form,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black, Colors.black, Color(0xFF1E1B4B)]),
        ),
        padding: const EdgeInsets.all(48),
        child: Stack(
          children: [
            Positioned(left: -144, bottom: -144, child: _Glow(size: 288, color: const Color(0xFF7E22CE).withValues(alpha: 0.30))),
            Positioned(right: -96, top: 200, child: _Glow(size: 192, color: const Color(0xFF4F46E5).withValues(alpha: 0.20))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Avatara Defence', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, height: 1.2)),
                      const SizedBox(height: 16),
                      Text(text, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 18, height: 1.6)),
                    ],
                  ),
                ),
                const Spacer(),
                Text('© ${DateTime.now().year} Avatara Defence', style: const TextStyle(color: Color(0xFF52525B), fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)])),
      );
}
