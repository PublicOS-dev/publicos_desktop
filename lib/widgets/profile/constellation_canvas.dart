import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The publicos.dev constellation, live: the org profile's page background,
/// only on the profile. A port of the publicos.dev landing canvas in the
/// layout of the still the org's background record points at: evenly spaced
/// nodes, a denser and brighter band across the top, which is the banner,
/// and the links that light up as nodes drift near each other.
///
/// Every other surface (banner strips in lists, sheets, other apps) keeps
/// painting the still from the record. Byte-identical twin in
/// publicos_desktop (`lib/widgets/profile/constellation_canvas.dart`).
///
/// The ticker runs only while the widget is mounted and visible
/// ([TickerMode]), so an off-screen profile spends nothing.
class ConstellationCanvas extends StatefulWidget {
  /// Same seed, same opening layout as the still (seed 7).
  final int seed;

  const ConstellationCanvas({super.key, this.seed = 7});

  /// The name the Easter egg answers to: the root org's profile.
  static bool isFor({required String displayName, required bool isOrg}) =>
      isOrg && displayName.toLowerCase() == 'publicos';

  @override
  State<ConstellationCanvas> createState() => _ConstellationCanvasState();
}

class _Moon {
  final double dist;
  final double angle;
  final double speed; // rad per 1/60 s, as landing.js
  final double r;
  _Moon(this.dist, this.angle, this.speed, this.r);
}

class _Node {
  final double x0, y0; // where the node starts; its place at time t is [at]
  double x = 0, y = 0; // the current frame's position (set by [at])
  final double vx, vy; // px per 1/60 s, as landing.js
  final double size;
  final bool citizen;
  final bool inBand; // band nodes wrap inside the band, so it never empties
  final List<_Moon> moons;
  _Node(this.x0, this.y0, this.vx, this.vy, this.size, this.citizen, this.inBand,
      this.moons);

  /// Position after [f] frames (1/60 s each), wrapped like landing.js: a
  /// pure function of time, so two canvases on screen (the page background
  /// and the profile header that repeats its top) draw the same frame.
  void at(double f, double w, double h, double bandBottom) {
    x = _wrap(x0 + vx * f, -20, w + 20);
    y = _wrap(y0 + vy * f, -20, inBand ? bandBottom : h + 20);
  }

  static double _wrap(double v, double lo, double hi) {
    final span = hi - lo;
    if (span <= 0) return v;
    return lo + ((v - lo) % span + span) % span;
  }
}

class _ConstellationCanvasState extends State<ConstellationCanvas>
    with SingleTickerProviderStateMixin {
  /// One clock for every canvas in the app, so the copies agree.
  static final Stopwatch _clock = Stopwatch()..start();

  late final Ticker _ticker;
  // Seeded from the shared clock, not 0: a freshly mounted canvas paints
  // once before its first tick, and at 0 that frame shows the t=0 layout
  // (a flash on every tab switch).
  final ValueNotifier<double> _frame =
      ValueNotifier(_clock.elapsedMicroseconds / 16667.0);
  List<_Node> _nodes = const [];
  Size _builtFor = Size.zero;
  _Geometry _geo = const _Geometry(0, 0, 0, 0, 0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _tick(Duration _) {
    _frame.value = _clock.elapsedMicroseconds / 16667.0;
  }

  void _build(Size size) {
    _builtFor = size;
    _geo = _Geometry.of(size);
    final rnd = math.Random(widget.seed);
    _Node make(math.Point<double> p, bool inBand) {
      final s = 4 + rnd.nextDouble() * 4;
      final moonCount = rnd.nextInt(3);
      final moons = <_Moon>[
        for (var m = 0; m < moonCount; m++)
          _Moon(
            s + 3 + rnd.nextDouble() * 6,
            rnd.nextDouble() * math.pi * 2,
            (0.003 + rnd.nextDouble() * 0.008) * (rnd.nextBool() ? 1 : -1),
            2 * (0.6 + rnd.nextDouble() * 0.5),
          ),
      ];
      return _Node(
        p.x,
        p.y,
        (rnd.nextDouble() - 0.5) * 0.15,
        (rnd.nextDouble() - 0.5) * 0.15,
        s,
        rnd.nextDouble() < 0.8,
        inBand,
        moons,
      );
    }

    final m = _geo.gap;
    final base = _poisson(rnd, size.width + 2 * m, size.height + 2 * m, _geo.gap)
        .map((p) => make(math.Point(p.x - m, p.y - m), false))
        .toList();
    final extra = <_Node>[];
    if (_geo.band > 0 && _geo.bandGap < _geo.gap) {
      for (final p in _poisson(rnd, size.width + 2 * m,
          _geo.band + _geo.fade * 0.5 + m, _geo.bandGap)) {
        final x = p.x - m, y = p.y - m;
        final clear = base.every((n) =>
            (n.x0 - x) * (n.x0 - x) + (n.y0 - y) * (n.y0 - y) >=
            _geo.bandGap * _geo.bandGap);
        if (clear) extra.add(make(math.Point(x, y), true));
      }
    }
    _nodes = [...base, ...extra];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      if (size.width > 0 && size.height > 0 && size != _builtFor) _build(size);
      return RepaintBoundary(
        child: CustomPaint(
          size: size,
          painter: _ConstellationPainter(_nodes, _geo, _frame),
        ),
      );
    });
  }
}

/// Spacing for a given box. `u` keeps a phone at the still's numbers (the
/// still is 360 site px wide) and lets a wide desktop pane space out a bit.
class _Geometry {
  final double gap, bandGap, band, fade, glow;
  const _Geometry(this.gap, this.bandGap, this.band, this.fade, this.glow);
  factory _Geometry.of(Size s) {
    final u = (s.width / 360).clamp(1.0, 1.6);
    // bandC: gap 75, band gap 40, band = the banner (width / 2.5), fade 80, glow 1.8.
    return _Geometry(75 * u, 40 * u, s.width / 2.5, 80 * u, 1.8);
  }

  static const reach = 2.4, boost = 2.5;

  double glowAt(double y) {
    if (band <= 0 || y <= band) return band <= 0 ? 1 : glow;
    if (y >= band + fade) return 1;
    var t = (y - band) / fade;
    t = t * t * (3 - 2 * t);
    return glow + (1 - glow) * t;
  }

  double gapAt(double y) => gap + (bandGap - gap) * (glowAt(y) - 1) / (glow - 1);
}

/// Bridson Poisson-disc, as `render.html`.
List<math.Point<double>> _poisson(math.Random rnd, double w, double h, double r) {
  final cell = r / math.sqrt2;
  final gw = (w / cell).ceil(), gh = (h / cell).ceil();
  final grid = List<int>.filled(gw * gh, -1);
  final pts = <math.Point<double>>[], active = <math.Point<double>>[];
  void add(math.Point<double> p) {
    pts.add(p);
    active.add(p);
    grid[(p.y / cell).floor() * gw + (p.x / cell).floor()] = pts.length - 1;
  }

  add(math.Point(rnd.nextDouble() * w, rnd.nextDouble() * h));
  while (active.isNotEmpty) {
    final ai = rnd.nextInt(active.length);
    final a = active[ai];
    var found = false;
    for (var k = 0; k < 30 && !found; k++) {
      final ang = rnd.nextDouble() * math.pi * 2, d = r * (1 + rnd.nextDouble());
      final x = a.x + math.cos(ang) * d, y = a.y + math.sin(ang) * d;
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      final gx = (x / cell).floor(), gy = (y / cell).floor();
      var ok = true;
      for (var yy = math.max(0, gy - 2); yy <= math.min(gh - 1, gy + 2) && ok; yy++) {
        for (var xx = math.max(0, gx - 2); xx <= math.min(gw - 1, gx + 2); xx++) {
          final idx = grid[yy * gw + xx];
          if (idx >= 0) {
            final dx = pts[idx].x - x, dy = pts[idx].y - y;
            if (dx * dx + dy * dy < r * r) {
              ok = false;
              break;
            }
          }
        }
      }
      if (ok) {
        add(math.Point(x, y));
        found = true;
      }
    }
    if (!found) active.removeAt(ai);
  }
  return pts;
}

class _ConstellationPainter extends CustomPainter {
  final List<_Node> nodes;
  final _Geometry geo;
  final ValueNotifier<double> frame;
  _ConstellationPainter(this.nodes, this.geo, this.frame)
      : super(repaint: frame);

  static const _ground = Color(0xFF0A0A0F);
  static const _teal = Color(0xFF14B8A6);
  static const _citizen = Color(0xFFF0F0F0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _ground);
    final f = frame.value;
    final bandBottom = geo.band + geo.fade * 0.5;
    for (final n in nodes) {
      n.at(f, size.width, size.height, bandBottom);
    }
    final line = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < nodes.length; i++) {
      final a = nodes[i];
      for (var j = i + 1; j < nodes.length; j++) {
        final b = nodes[j];
        final dx = a.x - b.x, dy = a.y - b.y;
        final md = _Geometry.reach * (geo.gapAt(a.y) + geo.gapAt(b.y)) / 2;
        if (dx.abs() > md || dy.abs() > md) continue;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist >= md) continue;
        final k = 1 - dist / md;
        final g = (geo.glowAt(a.y) + geo.glowAt(b.y)) / 2;
        line
          ..color = _teal.withValues(
              alpha: math.min(1.0, k * k * 0.12 * _Geometry.boost * g))
          ..strokeWidth = 0.5 + k * 0.8;
        canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), line);
      }
    }
    final fill = Paint();
    for (final n in nodes) {
      final c = n.citizen ? _citizen : _teal;
      final g = geo.glowAt(n.y);
      void rect(double cx, double cy, double w, double r, double alpha) {
        fill.color = c.withValues(alpha: math.min(1.0, alpha * g));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(cx, cy), width: w, height: w),
                Radius.circular(r)),
            fill);
      }

      rect(n.x, n.y, n.size, n.size * 0.45, n.citizen ? 0.22 : 0.25);
      rect(n.x, n.y + 1, n.size, n.size * 0.45, n.citizen ? 0.07 : 0.08);
      for (final m in n.moons) {
        final ang = m.angle + m.speed * f;
        rect(n.x + math.cos(ang) * m.dist, n.y + math.sin(ang) * m.dist,
            m.r * 2, m.r * 0.4, n.citizen ? 0.18 : 0.2);
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) =>
      old.nodes != nodes || old.geo != geo;
}
