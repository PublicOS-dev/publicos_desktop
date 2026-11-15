import 'package:flutter/widgets.dart';

/// Chrome that follows the content's scroll POSITION, never its activity.
///
/// Wrap the scrolling body with it and read the outer vertical list's
/// [ScrollMetrics] from [onMetrics]: the feeds header's divider, the
/// browser's collapsing header. Two notifications feed it, and only two:
///
/// - [ScrollUpdateNotification]: the position moved. Flutter dispatches it
///   from scroll ticks and drags, never from inside a layout pass.
/// - [ScrollMetricsNotification]: the extents changed with no movement, e.g.
///   a page that shrinks under a scrolled offset and has its `pixels`
///   corrected back (org Management). Flutter dispatches it after the frame.
///
/// Start, end and user-scroll notifications are deliberately NOT forwarded:
/// when a content-size change makes the framework re-run the physics inside
/// `performLayout`, those can fire mid-layout, and a `setState` or an
/// animation-value write in their handler throws "Build scheduled during
/// frame" and leaves the scroll position half-updated for good. Material's
/// own AppBar applies the same rule.
///
/// Only depth 0 counts (the body's own list); a nested vertical scroller
/// bubbles at depth >= 1 and must not drive the chrome. Horizontal rows are
/// ignored by axis.
class ContentMetricsListener extends StatelessWidget {
  final void Function(ScrollMetrics metrics) onMetrics;
  final Widget child;

  const ContentMetricsListener({
    super.key,
    required this.onMetrics,
    required this.child,
  });

  void _forward(ScrollMetrics metrics, int depth) {
    if (depth != 0 || metrics.axis != Axis.vertical) return;
    onMetrics(metrics);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        _forward(n.metrics, n.depth);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollUpdateNotification) _forward(n.metrics, n.depth);
          return false;
        },
        child: child,
      ),
    );
  }
}
