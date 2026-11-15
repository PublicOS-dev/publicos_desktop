import 'package:flutter/material.dart';

/// One item in a feed header's right-hand group (the key, the loader, the
/// "new posts" chip, the people and feeds buttons).
///
/// Give it a [child] to show, null to hide. Arriving, the slot opens its
/// width while the child rises from below and fades in; leaving, the child
/// sinks and fades, then the width closes, so the neighbours slide over into
/// the space. A child that only CHANGES (the key's glyph, the chip's count)
/// updates in place, no animation: the switch is keyed on present / absent.
class HeaderSlot extends StatelessWidget {
  final Widget? child;
  final Duration duration;

  const HeaderSlot({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
  });

  @override
  Widget build(BuildContext context) {
    final c = child;
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      // The child rises from BELOW the row; clipping would cut it off.
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (w, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.7),
              end: Offset.zero,
            ).animate(a),
            child: w,
          ),
        ),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [...previous, if (current != null) current],
        ),
        child: c == null
            ? const SizedBox.shrink(key: ValueKey<bool>(false))
            : KeyedSubtree(key: const ValueKey<bool>(true), child: c),
      ),
    );
  }
}
