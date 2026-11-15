import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A label whose glyphs rise and fall in a travelling wave.
///
/// The desktop loading caption. Pair it with a [PixelRainLoadingWidget] —
/// **logo first, caption second** — for any "we're doing work" row that has
/// something to say about what the work is: the browser's webview placeholder
/// (`browser/publicos_webview.dart`), the pre-login gate (`main.dart`) and the
/// login overlay (`screens/select_account_screen.dart`).
///
/// Built here rather than pulled from publicos_client: the client has no
/// equivalent.
///
/// Each glyph is its own [Text] offset by [Transform.translate], so the wave
/// costs no layout — the row's size never changes while it animates, and the
/// letters cannot reflow mid-cycle. Screen readers get the whole string once
/// rather than ten single characters.
class WaveText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const WaveText({super.key, required this.text, required this.style});

  /// How far a glyph rises at the top of its bump, in logical pixels.
  static const amplitude = 3.0;

  /// One full pass of the wave across the string.
  static const period = Duration(milliseconds: 1500);

  @override
  State<WaveText> createState() => _WaveTextState();
}

class _WaveTextState extends State<WaveText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: WaveText.period,
  )..repeat();

  /// Phase distance between neighbouring glyphs. Small enough that the crest
  /// reads as one travelling bump rather than each letter acting alone.
  static const _stagger = 0.055;

  /// The share of a cycle a glyph spends off the baseline. The rest is rest —
  /// without it every glyph is always mid-bump and the row just shimmers.
  static const _bump = 0.32;

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glyphs = widget.text.characters.toList();
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < glyphs.length; i++)
              Transform.translate(
                offset: Offset(0, -WaveText.amplitude * _liftAt(i)),
                child: Text(glyphs[i], style: widget.style),
              ),
          ],
        ),
      ),
    );
  }

  /// 0 at rest, 1 at the crest. A half sine over the bump window gives a rise
  /// and fall that lands back on the baseline exactly, so there is no jump
  /// when the glyph goes still.
  double _liftAt(int index) {
    final phase = (_wave.value - index * _stagger) % 1.0;
    if (phase >= _bump) return 0;
    return math.sin(phase / _bump * math.pi);
  }
}
