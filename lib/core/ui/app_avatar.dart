import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppAvatarSize { xs, sm, md, lg }

/// Round avatar with image, falling back to coloured initials (web `Avatar`).
/// Pass [colorSeed] (e.g. a user id) so a person always gets the same colour — the
/// same 8-colour rotation the web app uses.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.name, this.imageUrl, this.size = AppAvatarSize.md, this.colorSeed, this.color, this.ring = false});

  final String? name;
  final String? imageUrl;
  final AppAvatarSize size;
  final int? colorSeed;
  final Color? color;

  /// Background-coloured outline, used when avatars overlap in a stack.
  final bool ring;

  static const _palette = <Color>[
    TwColors.blue500,
    TwColors.violet500,
    TwColors.orange500,
    TwColors.emerald500,
    TwColors.rose500,
    TwColors.cyan600,
    TwColors.amber500,
    TwColors.indigo500,
  ];

  static Color colorFor(int? seed) => _palette[(seed ?? 0).abs() % _palette.length];

  /// "Rushikesh Ravtale" → "RR", "Purvesh" → "P".
  static String initialsOf(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  double get _dim => switch (size) {
        AppAvatarSize.xs => 20,
        AppAvatarSize.sm => 28,
        AppAvatarSize.md => 36,
        AppAvatarSize.lg => 48,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dim = _dim;
    final bg = color ?? colorFor(colorSeed);
    final initials = Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      color: bg,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: dim * 0.36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring ? c.background : c.border, width: ring ? 2 : 1),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(imageUrl!, width: dim, height: dim, fit: BoxFit.cover, errorBuilder: (_, _, _) => initials)
            : initials,
      ),
    );
  }
}

/// Overlapping avatars with a "+N" bubble (assignees on a task card).
class AppAvatarStack extends StatelessWidget {
  const AppAvatarStack({super.key, required this.people, this.max = 3, this.size = AppAvatarSize.sm});

  /// (name, optional colour seed, optional image) per person.
  final List<({String name, int? id, String? imageUrl})> people;
  final int max;
  final AppAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shown = people.take(max).toList();
    final extra = people.length - shown.length;
    final dim = switch (size) { AppAvatarSize.xs => 20.0, AppAvatarSize.sm => 28.0, AppAvatarSize.md => 36.0, AppAvatarSize.lg => 48.0 };
    final overlap = dim * 0.3;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      width: count == 0 ? 0 : dim + (count - 1) * (dim - overlap),
      height: dim,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (dim - overlap),
              child: AppAvatar(name: shown[i].name, imageUrl: shown[i].imageUrl, colorSeed: shown[i].id, size: size, ring: true),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * (dim - overlap),
              child: Container(
                width: dim,
                height: dim,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle, border: Border.all(color: c.background, width: 2)),
                child: Text('+$extra', style: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: dim * 0.34, fontWeight: FontWeight.w700, color: c.foreground)),
              ),
            ),
        ],
      ),
    );
  }
}
