import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';

/// A live "social graph" app icon: a small constellation of nodes wired by
/// connection lines, rendered on a frosted-glass tile.
///
/// This is a purpose-built miniature, NOT the full-screen
/// [ConstellationBackground] used on the onboarding screen — that one is a
/// free-drift field tuned for a ~400px canvas.
///
/// Layout model:
/// - **Static diamond lattice.** Nodes sit on a 7×7 grid rotated 45°, centred
///   on the tile, with a spacing that pushes the outer rings past the clip —
///   so links visibly run off the icon's edge, implying the graph continues
///   beyond the view. The rotation means node rows (and therefore every drawn
///   link) read as diagonals, never as flat horizontal/vertical lines.
/// - **Confined jitter.** Each node wanders slowly inside its own small cell
///   around its lattice point and never leaves it. The composition can't
///   clump or thin out — it is balanced by construction, forever — while the
///   field still reads as alive.
/// - **Stable edges.** Links are the precomputed lattice-neighbour pairs (the
///   two diagonal directions), so nothing pops in or out as nodes move; only
///   brightness breathes a little with the jitter.
/// - **Resolution-independent.** Positions are normalized to the unit square,
///   so a grid-size relayout just rescales the field — no re-seed, no jump.
class LiveGraphIcon extends StatefulWidget {
  /// Side length of the (square) tile, in logical px.
  final double size;

  /// Outer corner radius of the glass tile.
  final double cornerRadius;

  const LiveGraphIcon({
    super.key,
    required this.size,
    required this.cornerRadius,
  });

  @override
  State<LiveGraphIcon> createState() => _LiveGraphIconState();
}

class _LiveGraphIconState extends State<LiveGraphIcon>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _tick = ValueNotifier(0);
  final math.Random _rng = math.Random();
  final List<_GNode> _nodes = [];

  /// Lattice-neighbour index pairs — the only links ever drawn.
  final List<(int, int)> _edges = [];

  Duration _lastTick = Duration.zero;

  /// Lattice is [_gridN] × [_gridN]; the centre node sits at the tile centre.
  static const int _gridN = 7;

  /// Distance between lattice neighbours, normalized. At 0.34 the visible
  /// window shows the centre node plus ~1.5 rings; the rest of the lattice
  /// (and its links) overflows the clip.
  static const double _spacing = 0.34;

  /// Half-extent of the wander box around each node's lattice point. Small
  /// enough that neighbours (one [_spacing] apart) can never meet:
  /// 0.34 − 2×0.05 leaves a 0.24 gap at worst.
  static const double _jitter = 0.05;

  @override
  void initState() {
    super.initState();
    _initField();
    _ticker = createTicker(_onTick)..start();
  }

  void _initField() {
    _nodes.clear();
    _edges.clear();

    const c = (_gridN - 1) / 2;
    const invSqrt2 = 0.7071067811865476; // 45° lattice rotation

    int idx(int i, int j) => j * _gridN + i;
    // A couple of teal nodes / moon-bearers, pinned to lattice points that sit
    // in or near the visible window.
    final accents = {idx(4, 3), idx(3, 2)};
    final moonBearers = {idx(3, 3), idx(3, 4)};

    for (int j = 0; j < _gridN; j++) {
      for (int i = 0; i < _gridN; i++) {
        final u = (i - c) * _spacing;
        final v = (j - c) * _spacing;
        // Rotate the lattice offset 45° about the tile centre.
        final hx = 0.5 + (u - v) * invSqrt2;
        final hy = 0.5 + (u + v) * invSqrt2;

        // Very slow wander — crossing the tiny cell takes ~10s, so the field
        // reads as a stable structure that breathes, not as things moving.
        final speed = 0.008 + _rng.nextDouble() * 0.008; // normalized / sec
        final dir = _rng.nextDouble() * math.pi * 2;

        final moons = <_GMoon>[];
        if (moonBearers.contains(idx(i, j))) {
          moons.add(
            _GMoon(
              dist: 0.060 + _rng.nextDouble() * 0.030,
              angle: _rng.nextDouble() * math.pi * 2,
              speed: (0.05 + _rng.nextDouble() * 0.07) *
                  (_rng.nextBool() ? 1 : -1),
              r: 0.016,
            ),
          );
        }

        _nodes.add(
          _GNode(
            homeX: hx,
            homeY: hy,
            x: hx + (_rng.nextDouble() * 2 - 1) * _jitter,
            y: hy + (_rng.nextDouble() * 2 - 1) * _jitter,
            vx: math.cos(dir) * speed,
            vy: math.sin(dir) * speed,
            r: 0.030 + _rng.nextDouble() * 0.014, // half-size, normalized
            accent: accents.contains(idx(i, j)),
            moons: moons,
          ),
        );
      }
    }

    // Links between lattice neighbours along both lattice axes — on screen
    // (post-rotation) these are the two diagonal directions.
    for (int j = 0; j < _gridN; j++) {
      for (int i = 0; i < _gridN; i++) {
        if (i + 1 < _gridN) _edges.add((idx(i, j), idx(i + 1, j)));
        if (j + 1 < _gridN) _edges.add((idx(i, j), idx(i, j + 1)));
      }
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    // Skip the first (huge) frame and any pause-induced jump — same guard the
    // onboarding field uses, so a backgrounded tile doesn't lurch on resume.
    if (dt <= 0 || dt > 0.1) return;

    for (final n in _nodes) {
      // Meander: rotate the velocity by a small random amount so the path
      // curls instead of ping-ponging in straight lines.
      final turn = (_rng.nextDouble() * 2 - 1) * 1.2 * dt;
      final ca = math.cos(turn);
      final sa = math.sin(turn);
      final nvx = n.vx * ca - n.vy * sa;
      n.vy = n.vx * sa + n.vy * ca;
      n.vx = nvx;

      n.x += n.vx * dt;
      n.y += n.vy * dt;

      // Reflect off the node's own cell walls (and clamp, so a large dt can't
      // push it past the wall and trap it outside) — a node never leaves its
      // confined space.
      if (n.x < n.homeX - _jitter) {
        n.x = n.homeX - _jitter;
        n.vx = n.vx.abs();
      } else if (n.x > n.homeX + _jitter) {
        n.x = n.homeX + _jitter;
        n.vx = -n.vx.abs();
      }
      if (n.y < n.homeY - _jitter) {
        n.y = n.homeY - _jitter;
        n.vy = n.vy.abs();
      } else if (n.y > n.homeY + _jitter) {
        n.y = n.homeY + _jitter;
        n.vy = -n.vy.abs();
      }
      for (final m in n.moons) {
        m.angle += m.speed * dt;
      }
    }
    _tick.value = (_tick.value + 1) & 0xFFFFFF;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.cornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            // Translucent frosted panel — dark enough that the white/teal nodes
            // read, light enough that the backdrop blur shows through at the
            // edges. No accent border: only the subtle glass hairline the rest
            // of the grid uses.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tokens.surfaceElevated.withValues(alpha: 0.50),
                tokens.surfaceDeep.withValues(alpha: 0.68),
              ],
            ),
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: CustomPaint(
            painter: _GraphPainter(
              nodes: _nodes,
              edges: _edges,
              primary: tokens.starkWhite,
              accent: tokens.connectedAccent,
              spacing: _spacing,
              repaint: _tick,
            ),
          ),
        ),
      ),
    );
  }
}

class _GNode {
  final double homeX;
  final double homeY;
  double x;
  double y;
  double vx;
  double vy;
  final double r;
  final bool accent;
  final List<_GMoon> moons;

  _GNode({
    required this.homeX,
    required this.homeY,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.accent,
    required this.moons,
  });
}

class _GMoon {
  final double dist;
  double angle;
  final double speed;
  final double r;

  _GMoon({
    required this.dist,
    required this.angle,
    required this.speed,
    required this.r,
  });
}

class _GraphPainter extends CustomPainter {
  final List<_GNode> nodes;
  final List<(int, int)> edges;
  final Color primary;
  final Color accent;
  final double spacing;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.primary,
    required this.accent,
    required this.spacing,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset posOf(_GNode n) => Offset(n.x * w, n.y * h);

    // Edges — fixed neighbour pairs, so links never pop in/out; the jitter
    // only makes their brightness breathe. Edge length stays within
    // spacing ± 2×jitter, so map that band onto an alpha range.
    final linePaint = Paint()..style = PaintingStyle.stroke;
    for (final (ai, bi) in edges) {
      final a = nodes[ai];
      final b = nodes[bi];
      final dx = a.x - b.x;
      final dy = a.y - b.y;
      final dist = math.sqrt(dx * dx + dy * dy);
      final t =
          ((1.3 * spacing - dist) / (0.6 * spacing)).clamp(0.0, 1.0);
      linePaint
        ..color = primary.withValues(alpha: 0.16 + 0.5 * t)
        ..strokeWidth = (0.5 + t) * (w / 62);
      canvas.drawLine(posOf(a), posOf(b), linePaint);
    }

    // Nodes (rounded squares — the onboarding "planet" glyph) + a faint glow,
    // then any orbiting moons. Off-view lattice nodes are clipped by the tile.
    for (final n in nodes) {
      final c = n.accent ? accent : primary;
      final p = posOf(n);
      final full = n.r * 2 * w;
      _square(canvas, p, full * 1.7, c, 0.12); // glow
      _square(canvas, p, full, c, 0.95);
      for (final m in n.moons) {
        final mp = p +
            Offset(math.cos(m.angle), math.sin(m.angle)) * (m.dist * w);
        _square(canvas, mp, m.r * 2 * w, c, 0.7);
      }
    }
  }

  void _square(Canvas canvas, Offset center, double side, Color color,
      double alpha) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: side, height: side),
      Radius.circular(side * 0.3),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: alpha));
  }

  // Per-frame repainting is driven by the [repaint] Listenable; this only
  // matters for a colour/threshold change (e.g. a light/dark theme flip).
  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.primary != primary ||
      old.accent != accent ||
      old.spacing != spacing;
}
