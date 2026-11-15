import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';

/// [SystemAppActionButton] + its dashed disabled-state painter, lifted verbatim
/// from publicos_client's `components/system_app_scaffold.dart` (the rest of that
/// file is the mobile page scaffold, which desktop replaces with panes/dialogs).

class SystemAppActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// Optional tier colour: a tinted fill with the label and icon
  /// in that colour, for actions that must not look like the others — the
  /// Account app's renounce (softDanger) and delete-all-records
  /// (fallbackAccent). Null = the standard glass button.
  final Color? accent;

  const SystemAppActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final disabled = onTap == null;
    if (disabled) {
      // System-wide disabled style:
      // no fill, dashed border, dim text/icon. The dashed border is the
      // load-bearing signal that the affordance is unavailable.
      final disabledColor = tokens.textDim.withValues(alpha: 0.55);
      return SizedBox(
        width: double.infinity,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: tokens.borderSubtle,
            radius: 10,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: disabledColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 12,
                    color: disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent?.withValues(alpha: 0.12) ?? tokens.glassFill,
          foregroundColor: accent ?? tokens.starkWhite,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: accent?.withValues(alpha: 0.5) ?? tokens.borderMedium),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.color,
    this.radius = 10,
  });

  final Color color;
  final double radius;
  static const double dashWidth = 6;
  static const double dashGap = 4;
  static const double strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Inset by half the stroke so the border sits cleanly inside size.
    const inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final source = Path()..addRRect(rrect);

    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final next = distance + (draw ? dashWidth : dashGap);
        if (draw) {
          dashed.addPath(
            metric.extractPath(distance, next.clamp(0, metric.length)),
            Offset.zero,
          );
        }
        distance = next;
        draw = !draw;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
