import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The star on a contact's profile: a starred contact is one the
/// user gets chain notifications about.
///
/// The host draws its own chip around the glyph ([pill]), so the button
/// matches the row it sits in. Turning the star ON plays a short bounce and
/// three confetti dots; turning it off just empties the star.
class StarButton extends StatefulWidget {
  final bool starred;
  final VoidCallback onTap;

  /// The glyph's colour while the star is empty: the host's own icon colour.
  final Color idleColor;

  /// Wraps the 28x28 glyph in the host's chip.
  final Widget Function(Widget glyph) pill;

  final double size;
  final double iconSize;

  const StarButton({
    super.key,
    required this.starred,
    required this.onTap,
    required this.idleColor,
    required this.pill,
    this.size = 28,
    this.iconSize = 16,
  });

  /// The filled star.
  static const Color gold = Color(0xFFFFC83D);

  @override
  State<StarButton> createState() => _StarButtonState();
}

class _StarButtonState extends State<StarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// 1 → 1.4 → 1, with the settle doing the bounce.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.4)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.4, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 70,
    ),
  ]).animate(_c);

  @override
  void didUpdateWidget(covariant StarButton old) {
    super.didUpdateWidget(old);
    // Only a turn ON celebrates.
    if (!old.starred && widget.starred) {
      _c.forward(from: 0);
    } else if (old.starred && !widget.starred) {
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glyph = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.scale(
          scale: _c.isAnimating ? _scale.value : 1.0,
          child: Icon(
            widget.starred ? Icons.star_rounded : Icons.star_border_rounded,
            size: widget.iconSize + (widget.starred ? 2 : 0),
            color: widget.starred ? StarButton.gold : widget.idleColor,
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.pill(glyph),
          // The confetti is drawn OVER the chip and may leave its box: the
          // chip clips its own child, so it cannot live inside it.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(
                      _c.isAnimating || _c.value == 1 ? _c.value : -1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three dots that leave the star, upward and to the sides, and fade.
class _ConfettiPainter extends CustomPainter {
  /// 0..1 while playing; negative = nothing to draw.
  final double t;
  const _ConfettiPainter(this.t);

  static const _angles = [-150.0, -90.0, -30.0]; // degrees, up and outward
  static const _colors = [
    Color(0xFFFFC83D),
    Color(0xFFFF8A3D),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final travel = Curves.easeOutCubic.transform(t);
    final fade = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    for (var i = 0; i < _angles.length; i++) {
      final a = _angles[i] * math.pi / 180;
      final r = 8 + 16 * travel;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      canvas.drawCircle(
        p,
        2.2 - 0.8 * travel,
        Paint()..color = _colors[i].withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
