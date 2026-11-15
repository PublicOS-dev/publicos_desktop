import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The double-tap burst. The
/// reader's own double-tap emoji, big, rises from where the finger landed,
/// growing the whole way and fading at the end, with a handful of confetti
/// lines flying out of it: each a comet on its own path that shifts colour
/// as it goes, some of them tying one loop on the way (one at most per line,
/// not always). Every burst rolls its drift, lines, loops and colours from
/// [seed], so two taps never look the same. Paints only; the host places it
/// and drops it on [onDone].
class ReactionBurst extends StatefulWidget {
  final String emoji;
  final int seed;
  final VoidCallback onDone;

  /// The box the burst paints in, [size] square; the tap point sits at
  /// [originFraction] of its height so the rise has room above.
  static const double size = 240;
  static const double originFraction = 0.66;

  const ReactionBurst({
    super.key,
    required this.emoji,
    required this.seed,
    required this.onDone,
  });

  @override
  State<ReactionBurst> createState() => _ReactionBurstState();
}

class _ReactionBurstState extends State<ReactionBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  late final List<_Line> _lines;
  // Where the emoji goes: straight up, leaned up to 50 degrees left or right.
  late final double _driftAngle;
  late final TextPainter _glyph;

  static const double _glyphBase = 64;

  @override
  void initState() {
    super.initState();
    final r = math.Random(widget.seed);
    _driftAngle = -math.pi / 2 + (r.nextDouble() - 0.5) * (math.pi * 5 / 9);
    final n = 5 + r.nextInt(4); // 5..8 lines
    final spread = math.pi * 2 / n;
    _lines = [
      for (var i = 0; i < n; i++)
        _Line.roll(
          r,
          // Evenly around, each nudged so the fan is never a clock face.
          angle: spread * i + (r.nextDouble() - 0.5) * spread * 0.8,
          colorIndex: i,
        ),
    ];
    _glyph = TextPainter(
      text: TextSpan(
        text: widget.emoji,
        style: const TextStyle(fontSize: _glyphBase),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _t.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _t.dispose();
    _glyph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ReactionBurst.size,
      height: ReactionBurst.size,
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, __) => CustomPaint(
          painter: _ReactionBurstPainter(
            t: _t.value,
            lines: _lines,
            driftAngle: _driftAngle,
            glyph: _glyph,
            glyphBase: _glyphBase,
          ),
        ),
      ),
    );
  }
}

/// One confetti line, fixed at roll time: its path (relative to the emoji's
/// centre, pointing along [angle]), the loop it may tie, its timing and the
/// colour it starts on.
class _Line {
  final double angle;
  final double length;
  final double delay;
  final double width;
  final int colorIndex;

  /// The whole route, origin at the emoji's rim; drawn as a comet along it.
  final Path path;
  final double pathLength;

  const _Line({
    required this.angle,
    required this.length,
    required this.delay,
    required this.width,
    required this.colorIndex,
    required this.path,
    required this.pathLength,
  });

  factory _Line.roll(math.Random r, {required double angle, required int colorIndex}) {
    final length = 34.0 + r.nextDouble() * 30;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final perp = Offset(-dir.dy, dir.dx) * (r.nextBool() ? 1.0 : -1.0);
    // A gentle bend so the line never leaves dead straight.
    final bend = (r.nextDouble() - 0.5) * 18;
    // One loop on roughly half the lines, somewhere past the first third.
    final loops = r.nextDouble() < 0.55;
    final loopAt = 0.35 + r.nextDouble() * 0.3;
    final loopR = 4.0 + r.nextDouble() * 3.5;

    final path = Path()..moveTo(0, 0);
    if (loops) {
      final p = dir * (length * loopAt) + perp * (bend * loopAt);
      path.quadraticBezierTo(
        dir.dx * length * loopAt * 0.5 + perp.dx * bend * 0.2,
        dir.dy * length * loopAt * 0.5 + perp.dy * bend * 0.2,
        p.dx,
        p.dy,
      );
      // The loop: two half-circles out to the side and back to the same
      // point, so the comet keeps its heading after it.
      final far = p + perp * (loopR * 2);
      path.arcToPoint(far, radius: Radius.circular(loopR), clockwise: perp.dx * dir.dy - perp.dy * dir.dx > 0);
      path.arcToPoint(p, radius: Radius.circular(loopR), clockwise: perp.dx * dir.dy - perp.dy * dir.dx > 0);
      final end = dir * length + perp * bend;
      path.quadraticBezierTo(
        dir.dx * length * (loopAt + 1) / 2 + perp.dx * bend * 0.8,
        dir.dy * length * (loopAt + 1) / 2 + perp.dy * bend * 0.8,
        end.dx,
        end.dy,
      );
    } else {
      final end = dir * length + perp * bend;
      path.quadraticBezierTo(
        dir.dx * length * 0.5 + perp.dx * bend * 0.2,
        dir.dy * length * 0.5 + perp.dy * bend * 0.2,
        end.dx,
        end.dy,
      );
    }
    var total = 0.0;
    for (final m in path.computeMetrics()) {
      total += m.length;
    }
    return _Line(
      angle: angle,
      length: length,
      delay: r.nextDouble() * 0.18,
      width: 2 + r.nextDouble() * 1.5,
      colorIndex: colorIndex,
      path: path,
      pathLength: total,
    );
  }
}

class _ReactionBurstPainter extends CustomPainter {
  final double t;
  final List<_Line> lines;
  final double driftAngle;
  final TextPainter glyph;
  final double glyphBase;

  const _ReactionBurstPainter({
    required this.t,
    required this.lines,
    required this.driftAngle,
    required this.glyph,
    required this.glyphBase,
  });

  /// The confetti palette; a line starts on its own index and slides to the
  /// next colour over its life.
  static const List<Color> _confetti = [
    Color(0xFFFF5F6D),
    Color(0xFFFFC371),
    Color(0xFFF9F871),
    Color(0xFF7CF29C),
    Color(0xFF5AD1FF),
    Color(0xFFA77BFF),
    Color(0xFFFF8FD8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final origin =
        Offset(size.width / 2, size.height * ReactionBurst.originFraction);

    // The emoji: grows the whole way (never settles back), rises along the
    // drift, and fades over the last third.
    final grow = Curves.easeOutCubic.transform(t);
    final rise = Curves.easeOutQuad.transform(t) * 64;
    final fade = t < 0.6 ? 1.0 : 1 - Curves.easeIn.transform((t - 0.6) / 0.4);
    final c = origin + Offset(math.cos(driftAngle), math.sin(driftAngle)) * rise;
    final glyphSize = 28 + 64 * grow;
    // One swing about its centre as it travels, leaning first toward the
    // side it drifts to, then the other way, level again at the end.
    final lean = driftAngle > -math.pi / 2 ? 1.0 : -1.0;
    final tilt = lean * 0.21 * math.sin(t * math.pi * 2);
    if (fade > 0) {
      final scale = glyphSize / glyphBase;
      final box = Rect.fromCenter(
        center: c,
        width: glyph.width * scale + 24,
        height: glyph.height * scale + 24,
      );
      // A colour glyph ignores a text colour's alpha; the layer carries the
      // fade instead.
      canvas.saveLayer(box, Paint()..color = Color.fromRGBO(0, 0, 0, fade));
      canvas.translate(c.dx, c.dy);
      canvas.rotate(tilt);
      canvas.scale(scale);
      glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
      canvas.restore();
    }

    // The confetti: each line starts after its own delay and runs its route
    // from the emoji's rim as a comet (a moving window of the path), thinning
    // and sliding to the next colour as it goes.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final rim = glyphSize * 0.55;
    for (final line in lines) {
      final u = ((t - line.delay) / 0.6).clamp(0.0, 1.0);
      if (u <= 0 || u >= 1) continue;
      final travel = Curves.easeOut.transform(u);
      final head = line.pathLength * travel;
      final tail = math.max(0.0, head - line.pathLength * 0.38);
      final from = _confetti[line.colorIndex % _confetti.length];
      final to = _confetti[(line.colorIndex + 1) % _confetti.length];
      final color = Color.lerp(from, to, u)!.withValues(alpha: 1 - u * u);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = line.width * (1 - u * 0.6)
        ..strokeCap = StrokeCap.round;
      // The route starts at the rim, so shift it out along its heading.
      final offset = Offset(math.cos(line.angle), math.sin(line.angle)) * rim;
      for (final m in line.path.computeMetrics()) {
        final seg = m.extractPath(tail, head);
        canvas.drawPath(seg.shift(offset), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ReactionBurstPainter old) => old.t != t;
}
