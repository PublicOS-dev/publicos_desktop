import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Floating network-of-nodes background. Copied verbatim from publicos_client
/// (`components/constellation_background.dart`) — fully self-contained, no
/// PublicOS coupling. Planets drift, each with a few orbiting moons; nearby
/// planets are joined by faint connection lines (the "network" look).
class ConstellationBackground extends StatefulWidget {
  final Color color;
  final Color secondaryColor;
  final double secondaryRatio;
  final int planetCount;
  final double maxConnectionDistance;

  /// Global horizontal parallax offset (px). Shifts the whole field on X and
  /// wraps seamlessly at the edges.
  final double scrollX;

  const ConstellationBackground({
    super.key,
    this.color = const Color(0xFFFFFFFF),
    this.secondaryColor = const Color(0xFF14B8A6),
    this.secondaryRatio = 0.2,
    this.planetCount = 30,
    this.maxConnectionDistance = 350,
    this.scrollX = 0,
  });

  @override
  State<ConstellationBackground> createState() =>
      _ConstellationBackgroundState();
}

class _ConstellationBackgroundState extends State<ConstellationBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Planet> _planets = [];
  final ValueNotifier<int> _tick = ValueNotifier(0);

  /// The virtual field the planets live and wrap in — deliberately LARGER than
  /// the viewport (by [_buffer] on each axis) and grown monotonically so it
  /// always covers the largest viewport ever seen plus a margin. The viewport
  /// is just a window onto its top-left; growing the window reveals stars that
  /// were already drifting in the off-screen buffer, at constant density (no
  /// rescale, no drag, no black gap, no pop-in).
  Size _field = Size.zero;

  /// Planets per px², fixed at first layout from [widget.planetCount] over the
  /// initial viewport. Every later field-grow seeds the new region at this same
  /// density so the look never thins out.
  double _density = 0;

  final math.Random _rng = math.Random();
  Duration _lastTick = Duration.zero;

  /// Off-screen margin (px, each axis) kept seeded beyond the viewport so a
  /// drag-grow always pulls in already-populated space.
  static const double _buffer = 400;

  /// Hard cap on total planets so a maximized window on a 4K panel can't push
  /// the O(n²) line pass into jank. At the cap, very large fields go a touch
  /// sparser rather than slower.
  static const int _maxPlanets = 220;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  int _targetCount(Size field) =>
      (_density * field.width * field.height)
          .round()
          .clamp(widget.planetCount, _maxPlanets);

  _Planet _makePlanet(double x, double y) {
    final s = 4 + _rng.nextDouble() * 4;
    final moonCount = _rng.nextInt(3);
    final moons = <_Moon>[];
    for (int m = 0; m < moonCount; m++) {
      moons.add(
        _Moon(
          dist: s + 3 + _rng.nextDouble() * 6,
          angle: _rng.nextDouble() * math.pi * 2,
          speed: (0.15 + _rng.nextDouble() * 0.30) * (_rng.nextBool() ? 1 : -1),
          r: 2 * (0.6 + _rng.nextDouble() * 0.5),
        ),
      );
    }
    final isAccent = _rng.nextDouble() < widget.secondaryRatio;
    return _Planet(
      x: x,
      y: y,
      vx: (_rng.nextDouble() - 0.5) * 9.0,
      vy: (_rng.nextDouble() - 0.5) * 9.0,
      size: s,
      rx: s * 0.45,
      moons: moons,
      color: isAccent ? widget.secondaryColor : widget.color,
    );
  }

  /// First-layout seed: fill the whole (viewport + buffer) field at density.
  void _seedField(Size view) {
    _density = widget.planetCount / (view.width * view.height);
    _field = Size(view.width + _buffer, view.height + _buffer);
    final count = _targetCount(_field);
    for (int i = 0; i < count; i++) {
      _planets.add(
        _makePlanet(_rng.nextDouble() * _field.width,
            _rng.nextDouble() * _field.height),
      );
    }
  }

  /// On a viewport that has grown past the current field (+buffer), extend the
  /// field and seed ONLY the newly-added L-shaped region — which is still
  /// off-screen (it's in the buffer), so the new stars never pop into view.
  /// Shrinking is a no-op: the field and its stars are kept for when it grows
  /// back.
  void _growField(Size view) {
    final oldW = _field.width, oldH = _field.height;
    final newW = math.max(oldW, view.width + _buffer);
    final newH = math.max(oldH, view.height + _buffer);
    if (newW <= oldW && newH <= oldH) return;

    final add = _targetCount(Size(newW, newH)) - _planets.length;
    final rightArea = (newW - oldW) * newH;
    final bottomArea = oldW * (newH - oldH);
    final total = rightArea + bottomArea;
    for (int i = 0; i < add && total > 0; i++) {
      double x, y;
      if (_rng.nextDouble() * total < rightArea) {
        x = oldW + _rng.nextDouble() * (newW - oldW);
        y = _rng.nextDouble() * newH;
      } else {
        x = _rng.nextDouble() * oldW;
        y = oldH + _rng.nextDouble() * (newH - oldH);
      }
      _planets.add(_makePlanet(x, y));
    }
    _field = Size(newW, newH);
  }

  void _onTick(Duration elapsed) {
    if (_field.width <= 0 || _planets.isEmpty) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.1) return;

    // Wrap at the FIELD bounds, not the viewport — so planets drift through the
    // off-screen buffer and reappear, instead of being clamped to what's shown.
    final w = _field.width;
    final h = _field.height;
    for (final p in _planets) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.x < -20) p.x = w + 20;
      if (p.x > w + 20) p.x = -20;
      if (p.y < -20) p.y = h + 20;
      if (p.y > h + 20) p.y = -20;
      for (final m in p.moons) {
        m.angle += m.speed * dt;
      }
    }
    _tick.value = (_tick.value + 1) & 0xFFFFFF;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final view = Size(constraints.maxWidth, constraints.maxHeight);
        // Skip degenerate layouts (0 / unbounded).
        final valid = view.width > 0 &&
            view.height > 0 &&
            view.width.isFinite &&
            view.height.isFinite;
        if (valid) {
          if (_planets.isEmpty) {
            _seedField(view);
          } else {
            _growField(view);
          }
        }
        return CustomPaint(
          size: view,
          painter: _ConstellationPainter(
            planets: _planets,
            color: widget.color,
            maxDist: widget.maxConnectionDistance,
            scrollX: widget.scrollX,
            fieldWidth: _field.width,
            repaint: _tick,
          ),
        );
      },
    );
  }
}

class _Planet {
  double x;
  double y;
  double vx;
  double vy;
  final double size;
  final double rx;
  final List<_Moon> moons;
  final Color color;

  _Planet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rx,
    required this.moons,
    required this.color,
  });
}

class _Moon {
  final double dist;
  double angle;
  final double speed;
  final double r;

  _Moon({
    required this.dist,
    required this.angle,
    required this.speed,
    required this.r,
  });
}

class _ConstellationPainter extends CustomPainter {
  final List<_Planet> planets;
  final Color color;
  final double maxDist;
  final double scrollX;

  /// Width the parallax offset wraps around (the virtual field, not the
  /// canvas). Planets outside the canvas are simply clipped when drawn.
  final double fieldWidth;

  _ConstellationPainter({
    required this.planets,
    required this.color,
    required this.maxDist,
    required this.scrollX,
    required this.fieldWidth,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = fieldWidth > 0 ? fieldWidth : size.width;
    final xs = [
      for (final p in planets) ((p.x + scrollX) % w + w) % w,
    ];

    final linePaint = Paint()..style = PaintingStyle.stroke;
    for (int i = 0; i < planets.length; i++) {
      for (int j = i + 1; j < planets.length; j++) {
        final dx = xs[i] - xs[j];
        if (dx.abs() > maxDist) continue; // cheap reject before the sqrt
        final dy = planets[i].y - planets[j].y;
        if (dy.abs() > maxDist) continue;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < maxDist) {
          final intensity = 1 - dist / maxDist;
          final alpha = intensity * intensity * 0.12;
          linePaint
            ..color = color.withValues(alpha: alpha)
            ..strokeWidth = 0.5 + intensity * 0.8;
          canvas.drawLine(
            Offset(xs[i], planets[i].y),
            Offset(xs[j], planets[j].y),
            linePaint,
          );
        }
      }
    }

    for (int k = 0; k < planets.length; k++) {
      final p = planets[k];
      final cx = xs[k];
      _drawRRect(canvas, cx, p.y, p.size, p.size, p.rx, p.color, 0.25);
      _drawRRect(canvas, cx, p.y + 1, p.size, p.size, p.rx, p.color, 0.08);
      for (final m in p.moons) {
        final mx = cx + math.cos(m.angle) * m.dist;
        final my = p.y + math.sin(m.angle) * m.dist;
        _drawRRect(canvas, mx, my, m.r * 2, m.r * 2, m.r * 0.4, p.color, 0.2);
      }
    }
  }

  void _drawRRect(
    Canvas canvas,
    double cx,
    double cy,
    double w,
    double h,
    double r,
    Color color,
    double alpha,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      Radius.circular(r),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: alpha));
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.maxDist != maxDist ||
      oldDelegate.scrollX != scrollX ||
      oldDelegate.fieldWidth != fieldWidth;
}
