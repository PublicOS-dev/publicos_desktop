import 'dart:math';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

// Shared so the citizenship claim sheet can fire the same burst the
// onboarding gift page does.

/// A one-shot burst of square pixels.
///
/// Hand-rolled: a `CustomPainter` over one controller. Squares, no rotation and
/// no anti-aliased edges — the kit's own art is hard-edged geometry, so a
/// soft round-particle burst would read as borrowed from another app.
class PixelConfetti extends StatefulWidget {
  /// The kit's colours. Empty falls back to plain white, so a burst that fires
  /// before the art resolves still looks deliberate rather than broken.
  final List<Color> colors;

  const PixelConfetti({this.colors = const []});

  @override
  State<PixelConfetti> createState() => _PixelConfettiState();
}

class _PixelConfettiState extends State<PixelConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final List<_Pixel> _pixels;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // Seeded once, in initState: a rebuild mid-flight must not re-roll the
    // burst, or the pixels teleport.
    _pixels = List.generate(90, (i) {
      final angle = rng.nextDouble() * pi * 2;
      final speed = 0.35 + rng.nextDouble() * 0.85;
      return _Pixel(
        dx: cos(angle) * speed,
        dy: sin(angle) * speed - 0.45, // biased up, so it arcs
        size: 3.0 + rng.nextDouble() * 5.0,
        delay: rng.nextDouble() * 0.18,
        spinCells: rng.nextInt(4),
        // Assigned at SEED time, like everything else here: a colour rolled
        // per frame would make each pixel strobe through the palette.
        colorIndex: rng.nextInt(64),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _PixelConfettiPainter(
          t: _c.value,
          pixels: _pixels,
          colors: widget.colors.isEmpty ? [tokens.starkWhite] : widget.colors,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Pixel {
  final double dx;
  final double dy;
  final double size;
  final double delay;
  final int spinCells;

  /// Index into the palette, modulo its length — so one roll survives a
  /// palette that resolves later, or is shorter than expected.
  final int colorIndex;

  const _Pixel({
    required this.dx,
    required this.dy,
    required this.size,
    required this.delay,
    required this.spinCells,
    required this.colorIndex,
  });
}

class _PixelConfettiPainter extends CustomPainter {
  final double t;
  final List<_Pixel> pixels;
  final List<Color> colors;

  _PixelConfettiPainter({
    required this.t,
    required this.pixels,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.38);
    // The burst reaches roughly the short side, so it clears the art on a
    // phone without spraying off a tablet.
    final reach = size.shortestSide * 0.9;
    final paint = Paint()..isAntiAlias = false;

    for (final p in pixels) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      // Ease-out outward, constant-accel downward: a throw, not a explosion.
      final travel = 1 - pow(1 - local, 2.2);
      final x = origin.dx + p.dx * reach * travel;
      final y =
          origin.dy + p.dy * reach * travel + reach * 0.85 * local * local;

      // Fades only in the last third, so the burst reads as solid first.
      final alpha = local < 0.66 ? 1.0 : 1 - ((local - 0.66) / 0.34);
      paint.color = colors[p.colorIndex % colors.length]
          .withValues(alpha: alpha.clamp(0.0, 1.0) * 0.9);

      // "Spin" by snapping the size through a few cells rather than rotating —
      // a rotated square anti-aliases its edges and stops looking like a pixel.
      final wobble = 1.0 - 0.25 * ((p.spinCells + (local * 6).floor()) % 3);
      final s = p.size * wobble;
      canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y), width: s, height: s), paint);
    }
  }

  @override
  bool shouldRepaint(_PixelConfettiPainter old) =>
      old.t != t || old.colors != colors;
}
