import 'package:flutter/gestures.dart'
    show GestureBinding, PointerDeviceKind, PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Lets a mouse wheel scroll a horizontal list sideways while the pointer is
/// over it, like the Messages chips. Wrap any horizontal
/// `ListView` / `SingleChildScrollView`; no controller needed, the position is
/// picked up from the child's own scroll notifications.
///
/// A mouse wheel sends `dy` only, and a horizontal `Scrollable` reads `dx`, so
/// without this the list ignores the wheel. The guards are the ones
/// `ExplorerChipBar._onPointerSignal` documents: leave a trackpad's `dx` and
/// Shift+wheel to the list itself, and leave the event alone when the list has
/// nothing to scroll. One more here: the event is claimed through
/// [GestureBinding.pointerSignalResolver], so a page that scrolls vertically
/// around the list does not move at the same time, and at either end of the
/// list it is NOT claimed, so the wheel goes back to scrolling the page.
class HorizontalWheel extends StatefulWidget {
  final Widget child;

  const HorizontalWheel({super.key, required this.child});

  @override
  State<HorizontalWheel> createState() => _HorizontalWheelState();
}

class _HorizontalWheelState extends State<HorizontalWheel> {
  ScrollPosition? _position;

  bool _track(ScrollNotification n) {
    _capture(n.depth, n.metrics.axis, n.context);
    return false;
  }

  bool _trackMetrics(ScrollMetricsNotification n) {
    _capture(n.depth, n.metrics.axis, n.context);
    return false;
  }

  void _capture(int depth, Axis axis, BuildContext? context) {
    if (depth != 0 || axis != Axis.horizontal || context == null) return;
    _position = Scrollable.maybeOf(context)?.position;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    final pos = _position;
    if (event is! PointerScrollEvent || pos == null || !pos.hasPixels) return;
    final double dy = event.scrollDelta.dy;
    if (dy == 0 || event.scrollDelta.dx != 0) return;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight)) {
      return;
    }
    if (pos.maxScrollExtent <= pos.minScrollExtent) return;
    if ((dy < 0 && pos.pixels <= pos.minScrollExtent) ||
        (dy > 0 && pos.pixels >= pos.maxScrollExtent)) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      if (e is PointerScrollEvent) pos.pointerScroll(e.scrollDelta.dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _trackMetrics,
        child: NotificationListener<ScrollNotification>(
          onNotification: _track,
          // Mouse drag too: the default dragDevices leave the mouse out, so a
          // horizontal list is undraggable with one. The additive form keeps
          // the defaults; a list's own ScrollConfiguration still wins.
          child: ScrollConfiguration(
            behavior: behavior.copyWith(dragDevices: {
              ...behavior.dragDevices,
              PointerDeviceKind.mouse,
            }),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
