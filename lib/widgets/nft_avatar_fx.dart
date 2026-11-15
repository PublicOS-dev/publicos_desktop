import 'package:flutter/material.dart';

/// Shared "verified NFT" visual effects — the iridescent pixel sparkles and the
/// diagonal shimmer sweep that mark an avatar whose NFT ownership is verified.
///
/// Both painters are driven by a single 0..1 value representing progress through
/// a 10s cycle, so a caller animating one `AnimationController(duration: 10s)`
/// can phase-lock the two effects exactly as they were tuned: sparkles twinkle
/// in 0–2s windows, the shimmer sweeps at ~3.8–5.5s (just as the last sparkle
/// dims). Used by [GlassContactIcon] and the NFT info dialog so the live mark is
/// identical everywhere.

/// Iridescent pixel sparkles, top-left. Staggered pixels twinkle over a 10s
/// cycle (each on for ~2s of its window).
///
/// [focused] swaps the canonical 6-pixel avatar set for a doubled, wider-spread
/// 12-pixel set — used by the NFT-info dialog so the large "focused" art gets a
/// fuller corner burst (same dot size, just more of them over more space).
class NftSparklesPainter extends CustomPainter {
  final double t; // 0..1 of the 10s cycle
  final bool focused;
  NftSparklesPainter(this.t, {this.focused = false});

  // (dx, dy as fraction of box, base radius px, delay seconds). The box overhangs
  // the avatar's top-left corner, so the low-dx/low-dy pixels land OUTSIDE the
  // frame (the "live overlay, not a baked image" tell); the rest graze the body.
  static const List<List<double>> _layout = [
    [0.05, 0.13, 1.7, 0.0], // outside — far corner
    [0.15, 0.03, 1.3, 0.4], // outside — above the top edge
    [0.25, 0.22, 2.1, 0.8], // on the corner
    [0.11, 0.31, 1.5, 1.2], // outside — left of the edge
    [0.45, 0.17, 1.1, 1.6], // grazing the top
    [0.35, 0.47, 1.5, 2.0], // inside the body
  ];
  // Indices 1 & 5 are near-black so at least one sparkle stays visible against a
  // bright avatar/background; the rest are bright for dark backgrounds.
  static const List<Color> _colors = [
    Color(0xFF7C9CFF), // blue
    Color(0xFF14161D), // dark (outside)
    Color(0xFFFFD27A), // gold
    Color(0xFFA98BFF), // violet
    Color(0xFFFF7AB0), // pink
    Color(0xFF1B1424), // dark (inside)
  ];

  // 12-pixel "focused" set: same corner-overhang character, scattered over a
  // wider area (fractions reach ~0.7) with spacing, delays staggered across the
  // cycle so the burst keeps twinkling rather than blinking in lockstep.
  static const List<List<double>> _layoutWide = [
    [0.04, 0.10, 1.7, 0.0], // outside — far corner
    [0.14, 0.02, 1.3, 0.3], // outside — above the top edge
    [0.02, 0.28, 1.4, 0.6], // outside — left edge
    [0.24, 0.14, 2.1, 0.9], // near the corner
    [0.33, 0.05, 1.2, 1.2], // top, right of corner
    [0.10, 0.44, 1.5, 1.5], // left, lower
    [0.42, 0.30, 1.8, 1.8], // mid body
    [0.55, 0.13, 1.1, 2.1], // upper-right, scattered out
    [0.30, 0.55, 1.4, 2.4], // lower body
    [0.62, 0.42, 1.6, 2.7], // far lower-right
    [0.48, 0.64, 1.2, 3.0], // far lower
    [0.70, 0.26, 1.5, 3.3], // far right
  ];
  static const List<Color> _colorsWide = [
    Color(0xFF7C9CFF), // blue
    Color(0xFF14161D), // dark
    Color(0xFFFFD27A), // gold
    Color(0xFFA98BFF), // violet
    Color(0xFFFF7AB0), // pink
    Color(0xFF64FFDA), // teal (brand accent)
    Color(0xFF7AE7FF), // cyan
    Color(0xFFFFC078), // amber
    Color(0xFF1B1424), // dark
    Color(0xFFC9B8FF), // light violet
    Color(0xFFFF9EC4), // rose
    Color(0xFF101218), // dark
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final layout = focused ? _layoutWide : _layout;
    final colors = focused ? _colorsWide : _colors;
    final cycleSeconds = t * 10.0;
    for (var i = 0; i < layout.length; i++) {
      final l = layout[i];
      final delay = l[3];
      var local = cycleSeconds - delay;
      if (local < 0) local += 10.0;
      double op;
      if (local < 1.0) {
        op = local; // fade in
      } else if (local < 2.0) {
        op = 2.0 - local; // fade out
      } else {
        continue; // dark for the rest of the cycle
      }
      if (op <= 0.01) continue;
      final scale = 0.4 + 0.6 * op;
      final r = l[2] * scale;
      final c = colors[i].withValues(alpha: op.clamp(0.0, 1.0));
      final center = Offset(l[0] * size.width, l[1] * size.height);
      // soft glow + crisp core
      canvas.drawCircle(
          center, r * 2.2, Paint()..color = c.withValues(alpha: op * 0.35));
      canvas.drawCircle(center, r, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant NftSparklesPainter old) =>
      old.t != t || old.focused != focused;
}

/// Diagonal shimmer sweep across the avatar. Travels during ~3.8s–5.5s of the
/// 10s cycle — i.e. just as the last sparkle dims (phase-locked).
class NftShimmerPainter extends CustomPainter {
  final double t; // 0..1 of the 10s cycle
  NftShimmerPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    const startSec = 3.8;
    const travelSec = 1.7;
    final cycleSeconds = t * 10.0;
    final phase = cycleSeconds - startSec;
    if (phase < 0 || phase > travelSec) return;
    final f = phase / travelSec; // 0..1
    // Sweep center x from off-left to off-right.
    final cx = (-0.3 + 1.6 * f) * size.width;
    final bandW = size.width * 0.55;

    canvas.save();
    canvas.translate(cx, size.height / 2);
    canvas.rotate(-0.34); // ~ -20°
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: bandW,
      height: size.height * 2.4,
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00FFFFFF),
          Color(0x40FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant NftShimmerPainter old) => old.t != t;
}
