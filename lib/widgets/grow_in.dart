import 'package:flutter/material.dart';

/// One-shot entrance animation: the child fades in and grows (vertically
/// unfolds) into place instead of hard-popping. Built for list items — the
/// provider cards in the BSP/SSP dialogs — so a freshly-loaded list cascades
/// in rather than appearing all at once.
///
/// Give each instance a STABLE [key] (e.g. the item's id). With a stable key
/// the animation plays once on first mount and the finished state is preserved
/// across parent rebuilds; without one, every rebuild would restart it (and
/// these dialogs rebuild repeatedly as owner contacts resolve).
class GrowIn extends StatefulWidget {
  final Widget child;

  /// Delay before this item starts animating — pass `index * step` for a
  /// staggered cascade down a list.
  final Duration delay;
  final Duration duration;

  const GrowIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<GrowIn> createState() => _GrowInState();
}

class _GrowInState extends State<GrowIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SizeTransition(
        sizeFactor: _anim,
        alignment: Alignment.topCenter,
        child: widget.child,
      ),
    );
  }
}
