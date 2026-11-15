import 'package:flutter/material.dart';

import '../theme/glass_tokens.dart';

/// Dashed-border "add something" button. Extracted from the feeds drawer's
/// original Create-channel button so the same affordance reads identically
/// across the feeds surfaces: Create channel (drawer), Add a feed as a
/// single (Manage Lists footer), Add a feed to this list (Manage Lists
/// expanded-list row).
class DashedAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const DashedAddButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: DashedRoundedRectPainter(
            color: tokens.borderMedium,
            strokeWidth: 1,
            radius: 10,
            dashLength: 6,
            gapLength: 4,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: tokens.starkWhite),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          Offset.zero,
        );
        distance = next + gapLength;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(DashedRoundedRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
}
