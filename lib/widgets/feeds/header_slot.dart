import 'package:flutter/material.dart';

/// One item in a feed header's right-hand group.
///
/// Give it a [child] to show, null to hide. The motion has ONE direction,
/// left to right:
///
/// - **Arriving:** the slot opens its width first, then the child slides in
///   from the left while it fades in.
/// - **Leaving:** the child slides out to the right while it fades, then the
///   width closes, so the neighbours slide over into the space.
///
/// The two phases never overlap, and the child is pinned to the slot's left
/// edge, so nothing drifts while the width changes. A child that only
/// CHANGES (the key's glyph, the chip's count) updates in place, no
/// animation: the slot animates on present / absent only.
class HeaderSlot extends StatefulWidget {
  final Widget? child;
  final Duration duration;

  const HeaderSlot({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  /// How far (logical px) the child travels while it fades.
  static const double travel = 14;

  /// The share of the run the width takes; the child moves in the rest.
  static const double widthShare = 0.4;

  @override
  State<HeaderSlot> createState() => _HeaderSlotState();
}

class _HeaderSlotState extends State<HeaderSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  /// The child on screen: the current one, or the last one while it leaves.
  Widget? _shown;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _shown = widget.child;
    _c = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.child == null ? 0 : 1,
    )..addStatusListener((s) {
        if (s == AnimationStatus.dismissed && mounted) {
          setState(() => _shown = null);
        }
      });
  }

  @override
  void didUpdateWidget(HeaderSlot old) {
    super.didUpdateWidget(old);
    _c.duration = widget.duration;
    final next = widget.child;
    if (next != null) {
      _shown = next;
      if (old.child == null || _leaving) {
        // Arrive (or turn back mid-exit): always from the left.
        _leaving = false;
        _c.forward();
      }
    } else if (old.child != null) {
      _leaving = true;
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    const ws = HeaderSlot.widthShare;
    return AnimatedBuilder(
      animation: _c,
      child: shown,
      builder: (context, child) {
        final v = _c.value;
        // Width: the first share of an arrival, the last share of an exit
        // (on the way out v runs 1 -> 0, so that is v < ws either way).
        final width = Curves.easeInOutCubic
            .transform((v / ws).clamp(0.0, 1.0));
        // Content: 0 = away, 1 = at rest, over the rest of the run.
        final p = ((v - ws) / (1 - ws)).clamp(0.0, 1.0);
        final double dx;
        final double opacity;
        if (_leaving) {
          final out = Curves.easeInCubic.transform(1 - p);
          dx = HeaderSlot.travel * out;
          opacity = 1 - out;
        } else {
          final inn = Curves.easeOutCubic.transform(p);
          dx = -HeaderSlot.travel * (1 - inn);
          opacity = inn;
        }
        return ClipRect(
          // Clip only while the width is changing, so a resting child (the
          // loader's glow, a tooltip anchor) is never cut.
          clipBehavior: width < 1 ? Clip.hardEdge : Clip.none,
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: width,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(offset: Offset(dx, 0), child: child),
            ),
          ),
        );
      },
    );
  }
}
