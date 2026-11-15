import 'package:flutter/material.dart';

import '../theme/shell_tones.dart';

/// The shape a shell pane takes at rest: one content card, or a list card +
/// gap + content card ([ShellSplit]). `listWidth == 0` is the single card.
class ShellPaneShape {
  final double listWidth;
  const ShellPaneShape.single() : listWidth = 0;
  const ShellPaneShape.split(this.listWidth);
  bool get isSplit => listWidth > 0;

  @override
  bool operator ==(Object o) => o is ShellPaneShape && o.listWidth == listWidth;
  @override
  int get hashCode => listWidth.hashCode;
}

/// Animates the shell's pane area between two pane shapes instead of hard
/// swapping them (shell-wide, single ↔ split in both directions).
///
/// **Single → split.** The outgoing single card *becomes* the content card:
/// its left edge travels right from the rail to `listWidth + gap` while its
/// right edge stays, and the incoming pane's list card is revealed left to
/// right in the space it vacates — both on one clock. The outgoing fades in
/// its last third so the content underneath (the incoming pane's content
/// card, already at rest in the same rectangle) takes over without a blink.
///
/// **Split → single.** The reverse: the incoming single card starts on the
/// outgoing content card's rectangle and grows leftward to the rail, fading in
/// over the first half, while a canvas-toned curtain shrinks the outgoing list
/// card right to left just ahead of the sweeping edge.
///
/// **Split → split / single → single.** A plain crossfade.
///
/// **Why panes never remount.** Both the incoming and the outgoing pane are
/// placed in the [Stack] under a *GlobalKey* the shell owns per destination,
/// so the same element can sit in whichever slot the paint order needs
/// (over or under) and keep its state — the outgoing keeps rendering its real
/// content while it moves, the incoming keeps whatever it loaded.
///
/// Honours `MediaQuery.disableAnimations` (duration 0 → a hard swap).
class ShellMorph extends StatefulWidget {
  /// The current pane, laid out as it renders at rest — the split panes draw
  /// their own [ShellSplit], single panes come wrapped in a [ShellPanel]. Must
  /// carry a stable **GlobalKey** per destination.
  final Widget child;
  final ShellPaneShape shape;
  final Duration duration;

  const ShellMorph({
    super.key,
    required this.child,
    required this.shape,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  State<ShellMorph> createState() => _ShellMorphState();
}

class _ShellMorphState extends State<ShellMorph>
    with SingleTickerProviderStateMixin {
  // Created in initState, never lazily: a lazy `late final` is first touched
  // in dispose() when the shell unmounts before any pane switch (the first-run
  // swap to OnboardingFlow), and creating a ticker there throws "Looking up a
  // deactivated widget's ancestor is unsafe".
  late final AnimationController _c;

  Widget? _outgoing;
  ShellPaneShape? _outgoingShape;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() {
            _outgoing = null;
            _outgoingShape = null;
          });
        }
      });
  }

  @override
  void didUpdateWidget(ShellMorph old) {
    super.didUpdateWidget(old);
    if (old.child.key != widget.child.key) {
      // A rapid second switch mid-flight drops the older outgoing (it simply
      // unmounts) and restarts from the pane that was current a moment ago.
      _outgoing = old.child;
      _outgoingShape = old.shape;
      final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      _c.duration = reduce ? Duration.zero : widget.duration;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final out = _outgoing;
    if (out == null) {
      return Stack(children: [Positioned.fill(child: widget.child)]);
    }
    final tones = ShellTones.of(context);
    final from = _outgoingShape!;
    final to = widget.shape;
    const gap = ShellMetrics.gap;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final raw = _c.value;
        if (!from.isSplit && to.isSplit) {
          // ── single → split ────────────────────────────────────────────────
          final t = Curves.easeOutCubic.transform(raw);
          final left = (to.listWidth + gap) * t;
          final fade = 1 - Curves.easeIn.transform(((raw - 0.62) / 0.38).clamp(0.0, 1.0));
          return Stack(
            children: [
              Positioned.fill(child: widget.child),
              Positioned(
                left: left,
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(child: Opacity(opacity: fade, child: out)),
              ),
            ],
          );
        }
        if (from.isSplit && !to.isSplit) {
          // ── split → single ────────────────────────────────────────────────
          final t = Curves.easeInOutCubic.transform(raw);
          final left = (from.listWidth + gap) * (1 - t);
          final curtainLeft = from.listWidth * (1 - t);
          final fadeIn = Curves.easeOut.transform((raw / 0.5).clamp(0.0, 1.0));
          return Stack(
            children: [
              Positioned.fill(child: IgnorePointer(child: out)),
              // The list card shrinks right → left, one gap ahead of the edge.
              Positioned(
                left: curtainLeft,
                width: from.listWidth - curtainLeft,
                top: 0,
                bottom: 0,
                child: ColoredBox(color: tones.canvas),
              ),
              Positioned(
                left: left,
                right: 0,
                top: 0,
                bottom: 0,
                child: Opacity(opacity: fadeIn, child: widget.child),
              ),
            ],
          );
        }
        // ── same shape family: crossfade ──────────────────────────────────
        final fadeIn = Curves.easeOut.transform(raw);
        return Stack(
          children: [
            Positioned.fill(child: IgnorePointer(child: out)),
            Positioned.fill(child: Opacity(opacity: fadeIn, child: widget.child)),
          ],
        );
      },
    );
  }
}
