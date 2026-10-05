import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/core.dart';

/// Dashed "drop files here / click to browse" box used by the document sections.
/// Design preview: tapping calls [onTap]; real file picking arrives with the API step.
class UploadZone extends StatelessWidget {
  const UploadZone({super.key, required this.onTap, this.title = 'Click to upload', this.subtitle = 'or drag & drop · max 10MB', this.hint, this.busy = false, this.enabled = true, this.compact = false});

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String? hint;
  final bool busy;
  final bool enabled;

  /// One-line variant (task documents card).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final icon = busy ? const AppSpinner(size: 28) : Icon(LucideIcons.cloudUpload, size: compact ? 18 : 32, color: c.mutedForeground);
    final texts = Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(busy ? 'Uploading…' : title, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(subtitle, style: t.bodySmall),
        if (hint != null) ...[const SizedBox(height: 6), Text(hint!, style: t.bodySmall?.copyWith(fontSize: 10))],
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        borderRadius: AppRadius.rXl,
        onTap: enabled && !busy ? onTap : null,
        child: CustomPaint(
          painter: _DashedBorder(color: c.border, radius: AppRadius.xl),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: compact ? 14 : 24, horizontal: 16),
            decoration: BoxDecoration(color: c.muted.withValues(alpha: 0.2), borderRadius: AppRadius.rXl),
            child: compact
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [icon, const SizedBox(width: 12), texts])
                : Column(children: [icon, const SizedBox(height: 8), texts]),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder old) => old.color != color || old.radius != radius;
}

/// Icon for a file extension (web `fileIcon`).
({IconData icon, Color color}) fileIconFor(String? ext) {
  final e = (ext ?? '').toLowerCase();
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(e)) return (icon: LucideIcons.fileImage, color: TwColors.blue700);
  if (e == 'pdf') return (icon: LucideIcons.fileText, color: TwColors.red700);
  if (['doc', 'docx'].contains(e)) return (icon: LucideIcons.fileText, color: TwColors.blue500);
  if (['xls', 'xlsx', 'csv'].contains(e)) return (icon: LucideIcons.fileText, color: TwColors.emerald600);
  return (icon: LucideIcons.file, color: const Color(0xFF79697B));
}

/// One uploaded file in a list.
class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.name, this.ext, this.meta, this.onDelete, this.onOpen});

  final String name;
  final String? ext;
  final String? meta;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final f = fileIconFor(ext);
    return InkWell(
      borderRadius: AppRadius.rLg,
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(color: c.muted.withValues(alpha: 0.2), border: Border.all(color: c.border.withValues(alpha: 0.6)), borderRadius: AppRadius.rLg),
        child: Row(
          children: [
            Icon(f.icon, size: 18, color: f.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
                  if (meta != null) Text(meta!, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
            if (onDelete != null) AppIconButton(icon: LucideIcons.x, size: AppButtonSize.sm, tooltip: 'Remove', onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
