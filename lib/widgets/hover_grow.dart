import 'package:flutter/material.dart';

/// Desktop hover feedback for an emoji cell: the hovered emoji grows and
/// shrinks back when un-hovered, while its container keeps its size. The
/// hover area FILLS
/// the cell it is placed in (the parent's max constraints), the glyph sits
/// centred in it, so neighbouring cells hand the hover over with no dead
/// strip between them. Scales [child] by
/// (`size` + [grow]) / `size` while the pointer is over it, back to 1 when it
/// leaves, in [duration]. A transform, never layout: the cell keeps its box,
/// the glyph just paints bigger around its own centre.
///
/// Used by the reaction quick bar, the full emoji picker's tiles and the chat
/// long-press bar. Mobile has no hover, so this is a desktop-only widget.
class HoverGrow extends StatefulWidget {
  /// The glyph's own size in px (the emoji's font size), the base [grow] is
  /// measured against.
  final double size;
  final double grow;
  final Duration duration;
  final Widget child;

  const HoverGrow({
    super.key,
    required this.size,
    required this.child,
    this.grow = 8,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<HoverGrow> createState() => _HoverGrowState();
}

class _HoverGrowState extends State<HoverGrow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scale = _hover ? (widget.size + widget.grow) / widget.size : 1.0;
    // Opaque hit test: the empty part of the cell counts as "over it" (a
    // Center alone is only hit where its child is). The cell's tap handler
    // wraps this from outside, so it still gets the click.
    //
    // `opaque` MUST stay true (the default). RenderMouseRegion.hitTest returns
    // `super.hitTest(...) && opaque`, so with `opaque: false` this subtree
    // reports "not hit" to its parent and a plain GestureDetector around it
    // (deferToChild) never sees the click. InkWell/InkResponse are not
    // affected only because they hit-test opaquely on their own.
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SizedBox.expand(
        child: Center(
          child: AnimatedScale(
            scale: scale,
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
