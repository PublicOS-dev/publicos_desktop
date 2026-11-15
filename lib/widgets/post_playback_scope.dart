import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// One inline video plays at a time on a post list.
///
/// It is owned by the post-list renderer and knows nothing about feeds —
/// bookmarks and Explore ride it too.
///
/// The list that scrolls owns one [PostPlaybackController] and places it above
/// its scroll view with [PostPlaybackScope]. Every inline video tile under it
/// measures its own box against the scrollable's viewport after each scroll
/// frame and reports its visible fraction; the controller picks the single
/// **active** tile, and only the active tile mounts a player. The others show
/// their poster frame and hold no decoder at all (a paused ExoPlayer keeps its
/// buffers on the Java heap, enough of them to run the app out of memory).
/// Two things carry across the hand-over: the user's mute choice for the
/// session, and the position each clip was at.
///
/// Rules:
/// - A tile needs at least [winFraction] of itself on screen to win; among
///   those, the most visible wins, ties go to the one higher on screen.
/// - The active tile keeps the slot while at least [keepFraction] of it is on
///   screen and nothing is strictly more visible.
/// - A change of winner has to hold for [settle] before it is applied, so a
///   fling does not mount and tear down three decoders in a second.
/// - A tap on a non-active tile claims the slot regardless of geometry.
/// - No scope above a tile (post detail page, chat, previews) means the tile
///   is always active, which is the behaviour those surfaces had before.
class PostPlaybackController extends ChangeNotifier {
  static const double winFraction = 0.5;
  static const double keepFraction = 0.3;
  static const Duration settle = Duration(milliseconds: 200);

  String? _activeId;
  bool _muted = true;
  final Map<String, _Sighting> _seen = {};
  final Map<String, Duration> _positions = {};
  String? _candidate;
  Timer? _settleTimer;
  bool _tickScheduled = false;
  bool _disposed = false;

  /// Bumped once per frame after the list scrolled; tiles listen to it and
  /// re-measure. Kept apart from [notifyListeners] so a scroll frame does not
  /// rebuild every tile, only a change of winner does.
  final ValueNotifier<int> scrollTick = ValueNotifier<int>(0);

  /// The tile that may hold a player right now, by its id (the hero tag).
  String? get activeId => _activeId;

  /// The session's mute choice: starts muted, follows the user's last toggle
  /// on an inline tile, and the next winner starts with it.
  bool get muted => _muted;

  /// Called by the scope on every scroll notification; coalesces to one
  /// measurement pass per frame, after layout.
  void onScroll() {
    if (_tickScheduled || _disposed) return;
    _tickScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _tickScheduled = false;
      if (!_disposed) scrollTick.value++;
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  /// A tile reporting how much of it is on screen (0..1) and where its top
  /// sits relative to the viewport's top.
  void report(String id, {required double fraction, required double top}) {
    if (_disposed) return;
    _seen[id] = _Sighting(fraction, top);
    _decide();
  }

  /// A tile left the tree. It calls from its `dispose`, inside a locked
  /// frame, so the winner change is announced after the frame.
  void forget(String id) {
    if (_disposed) return;
    _seen.remove(id);
    if (_activeId == id) {
      _activeId = null;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
      SchedulerBinding.instance.scheduleFrame();
    }
    _decide();
  }

  /// The user tapped a non-active tile: it wins now, no settling.
  void claim(String id) {
    if (_disposed) return;
    _settleTimer?.cancel();
    _candidate = null;
    if (_activeId == id) return;
    _activeId = id;
    notifyListeners();
  }

  /// Mute is read when a winner mounts, so no rebuild is needed here.
  void setMuted(bool value) {
    _muted = value;
  }

  void savePosition(String id, Duration position) {
    _positions[id] = position;
  }

  Duration? positionFor(String id) => _positions[id];

  void _decide() {
    String? best;
    double bestFraction = 0;
    double bestTop = double.infinity;
    _seen.forEach((id, s) {
      if (s.fraction < winFraction) return;
      final clearlyMore = s.fraction > bestFraction + 0.05;
      final aboutEqual = (s.fraction - bestFraction).abs() <= 0.05;
      if (best == null || clearlyMore || (aboutEqual && s.top < bestTop)) {
        best = id;
        bestFraction = s.fraction;
        bestTop = s.top;
      }
    });

    final current = _activeId;
    final currentFraction =
        current == null ? 0.0 : (_seen[current]?.fraction ?? 0.0);
    String? next;
    if (current != null && currentFraction >= keepFraction) {
      // Holding: only a strictly more visible tile takes the slot.
      next = (best != null && best != current && bestFraction > currentFraction)
          ? best
          : current;
    } else {
      next = best;
    }
    _propose(next);
  }

  void _propose(String? next) {
    if (next == _activeId) {
      _settleTimer?.cancel();
      _candidate = null;
      return;
    }
    if (_candidate == next && (_settleTimer?.isActive ?? false)) return;
    _candidate = next;
    _settleTimer?.cancel();
    _settleTimer = Timer(settle, () {
      if (_disposed || _candidate != next) return;
      _candidate = null;
      _activeId = next;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _settleTimer?.cancel();
    scrollTick.dispose();
    super.dispose();
  }
}

class _Sighting {
  final double fraction;
  final double top;
  const _Sighting(this.fraction, this.top);
}

/// Places a [PostPlaybackController] above a scrolling list of posts and
/// feeds it the list's scroll notifications. Tiles find it with [maybeOf]
/// (rebuild on a change of winner) or [read] (no dependency).
class PostPlaybackScope extends InheritedNotifier<PostPlaybackController> {
  const PostPlaybackScope({
    super.key,
    required PostPlaybackController controller,
    required super.child,
  }) : super(notifier: controller);

  static PostPlaybackController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PostPlaybackScope>()
      ?.notifier;

  static PostPlaybackController? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PostPlaybackScope>()?.notifier;

  /// Wraps [child] so the list's scroll notifications reach the controller.
  static Widget wrap({
    required PostPlaybackController controller,
    required Widget child,
  }) {
    return PostPlaybackScope(
      controller: controller,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          controller.onScroll();
          return false;
        },
        child: child,
      ),
    );
  }
}

/// How much of the widget at [context] is inside the viewport of the nearest
/// scrollable that scrolls VERTICALLY (0..1), and where its top sits relative
/// to that viewport's top. The feed list is the one that matters: a tile
/// inside a horizontal pager (a page of the hero pager) fills its pager, so
/// measuring against the pager would say "all on screen" even for a card
/// scrolled away. Null when either box is not laid out yet.
///
/// [of] measures ANOTHER widget's box (the post card) against the scrollable
/// found from [context]: the audio row reports its whole post, not its own
/// 50 px, so the sound track plays while the post is on screen and stops
/// only when the POST is out of screen.
///
/// The fraction is of the box OR of the viewport, whichever is shorter: a
/// post taller than the screen filling the whole viewport reads 1.0, where a
/// fraction of its own height could never reach the 50 % win line and the
/// slot would stay empty.
({double fraction, double top})? measureVisibility(
  BuildContext context, {
  BuildContext? of,
}) {
  final box = (of ?? context).findRenderObject();
  if (box is! RenderBox || !box.hasSize || !box.attached) return null;
  final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
  final viewport = scrollable?.context.findRenderObject();
  if (viewport is! RenderBox || !viewport.hasSize || !viewport.attached) {
    return null;
  }
  final tileTop = box.localToGlobal(Offset.zero).dy;
  final tileBottom = tileTop + box.size.height;
  final viewTop = viewport.localToGlobal(Offset.zero).dy;
  final viewBottom = viewTop + viewport.size.height;
  final visible =
      math.min(tileBottom, viewBottom) - math.max(tileTop, viewTop);
  final span = math.min(box.size.height, viewport.size.height);
  final fraction = span <= 0 ? 0.0 : (visible / span).clamp(0.0, 1.0);
  return (fraction: fraction, top: tileTop - viewTop);
}
