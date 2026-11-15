import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:publicos_desktop/router.dart' show appRouteObserver;
import 'package:publicos_desktop/widgets/post_playback_scope.dart';
import 'package:publicos_desktop/widgets/video_controls_pill.dart';
import 'package:video_player/video_player.dart';

/// The post's one sound track (PublicOS Feed v1 `audio`), drawn as ONE row
/// on every post: under the hero when there is one, in the same spot (above
/// the text) when there is none. The same widget is the composer's preview.
///
/// Left to right: the play/pause disc, the title with small live bars while
/// playing, the scrub line with elapsed and total under the title, the loop
/// toggle (the hero video's repeat disc, [VideoGlassButton]), the mute disc,
/// and in the composer a remove glyph. No border on the container; every
/// control takes [color], which is the text colour by default and the
/// author's `color` record when they have one (the message bubble's rule).
///
/// Playback is `video_player` on the file (ExoPlayer · AVPlayer · libmpv all
/// decode audio; no video surface is mounted). The controller is created on
/// the first play tap, never at build, so a feed of audio posts holds no
/// decoder until one is asked for; the composer passes [eager] to learn the
/// duration at once. One row plays at a time across the app: starting one
/// pauses the other.
class PostAudioRow extends StatefulWidget {
  /// The remote file. One of [url] / [bytes] is required.
  final String? url;

  /// The local bytes (the composer's draft): written once to the temp dir and
  /// played from there. Not on web, where the row waits for the URL.
  final Uint8List? bytes;
  final String? filename;

  /// Shown at the left of the line. The media object's `title`, else the
  /// file's name.
  final String title;

  /// The media object's `duration_in_seconds`, shown until the file is
  /// opened and tells its own.
  final num? durationHint;

  /// The author's intent (`loop` on the media object); the toggle starts
  /// from it. The composer listens with [onLoopChanged] and signs it.
  final bool loop;
  final ValueChanged<bool>? onLoopChanged;

  /// The row's colour: discs, title, line, times, glyphs.
  final Color color;

  /// Composer only: the remove glyph at the right end.
  final VoidCallback? onRemove;

  /// Open the file at mount (the composer: one row, the duration goes into
  /// the signed media object through [onDuration]).
  final bool eager;
  final ValueChanged<Duration>? onDuration;

  /// The feed's playback rules, the inline video's: it autoplays when a
  /// video would and stops when a video would. With an id the row competes
  /// for the list's one slot
  /// under it ([PostPlaybackScope]): it plays when it wins, with the slot's
  /// mute choice, and pauses when it loses or scrolls out; with no scope
  /// above (the focused post) it is always the winner, like a video there.
  /// With or without an id it pauses under a covering route and offstage.
  /// Null (the composer) = manual play only.
  final String? playbackId;

  /// The post card's box, measured in place of the row's own, so playback
  /// stops only when the POST is off screen: under a tall hero the row
  /// itself leaves the viewport while the reader is still on the pictures.
  /// Null = measure the row.
  final GlobalKey? postKey;

  const PostAudioRow({
    super.key,
    this.url,
    this.bytes,
    this.filename,
    required this.title,
    this.durationHint,
    this.loop = false,
    this.onLoopChanged,
    required this.color,
    this.onRemove,
    this.eager = false,
    this.onDuration,
    this.playbackId,
    this.postKey,
  }) : assert(url != null || bytes != null);

  /// The message bubble's foreground crossover (hand-copied on purpose): a
  /// glyph on a disc filled with [color] is white below it, black above it.
  static const double fgCrossover = 0.179;

  static Color foregroundOn(Color fill) =>
      fill.computeLuminance() < fgCrossover ? Colors.white : Colors.black;

  @override
  State<PostAudioRow> createState() => _PostAudioRowState();
}

class _PostAudioRowState extends State<PostAudioRow>
    with SingleTickerProviderStateMixin, RouteAware {
  /// The row playing right now, app-wide; starting another pauses it.
  static _PostAudioRowState? _playing;

  // The list's one-at-a-time slot (post_playback_scope.dart), the video
  // tile's wiring: measure on each scroll tick, report, follow the winner.
  PostPlaybackController? _playback;
  bool _wasActive = false;
  // False under a hidden shell tab (TickerMode) or a route pushed on top.
  bool _onstage = true;
  bool _covered = false;

  VideoPlayerController? _ctrl;
  Future<void>? _opening;
  bool _loop = false;
  bool _muted = false;
  bool _failed = false;

  /// While a finger is on the line: the fraction under it.
  double? _scrub;

  /// Built in initState, NOT lazily: a lazy `late final` that was never read
  /// gets created inside dispose() (`_bars.dispose()`), and creating a ticker
  /// on a deactivated element throws mid-unmount. That half-unmounted subtree
  /// then breaks the whole feed list (red screen, snapping dead).
  late final AnimationController _bars;

  bool get _isPlaying => _ctrl?.value.isPlaying ?? false;

  Duration get _duration {
    final d = _ctrl?.value.duration;
    if (d != null && d > Duration.zero) return d;
    final hint = widget.durationHint;
    return hint == null
        ? Duration.zero
        : Duration(milliseconds: (hint * 1000).round());
  }

  Duration get _position => _ctrl?.value.position ?? Duration.zero;

  @override
  void initState() {
    super.initState();
    _bars = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loop = widget.loop;
    if (widget.eager) _open();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
    _onstage = TickerMode.valuesOf(context).enabled;
    final playback =
        widget.playbackId == null ? null : PostPlaybackScope.maybeOf(context);
    if (!identical(playback, _playback)) {
      _playback?.removeListener(_syncPlayback);
      _playback?.scrollTick.removeListener(_measure);
      _playback = playback;
      _playback?.addListener(_syncPlayback);
      _playback?.scrollTick.addListener(_measure);
      _scheduleMeasure();
    }
    _syncPlayback();
  }

  @override
  void didPushNext() {
    _covered = true;
    _syncPlayback();
  }

  @override
  void didPopNext() {
    _covered = false;
    _syncPlayback();
  }

  void _scheduleMeasure() {
    if (_playback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final playback = _playback;
    final id = widget.playbackId;
    if (playback == null || id == null || !mounted) return;
    // The post's fraction, the row's own top: the fraction keeps the sound
    // on while the post is on screen; the top keeps today's tie-break, so a
    // hero video of the same post (higher up) still wins the slot over the
    // row when both read equally visible.
    final seen = measureVisibility(context, of: widget.postKey?.currentContext);
    if (seen == null) return;
    final own = measureVisibility(context);
    playback.report(id, fraction: seen.fraction, top: own?.top ?? seen.top);
  }

  /// The one decision: covered or offstage pauses whatever the slot says;
  /// otherwise the row plays while it is the list's winner (or there is no
  /// list) and pauses when it is not. The composer (no id) never autoplays.
  void _syncPlayback() {
    if (!mounted) return;
    if (!_onstage || _covered) {
      _wasActive = false;
      _pause();
      return;
    }
    final id = widget.playbackId;
    if (id == null) return;
    final active = _playback == null || _playback!.activeId == id;
    if (active == _wasActive) return;
    _wasActive = active;
    if (active) {
      _autoplay();
    } else {
      _pause();
    }
  }

  /// The slot is this row's: play. Audio always starts UNMUTED, unlike a
  /// video, which takes the list's mute choice; the row's mute button still
  /// works for the session.
  Future<void> _autoplay() async {
    if (_failed) return;
    _muted = false;
    await _open();
    final c = _ctrl;
    if (c == null || !mounted || !_wasActive) return;
    await c.setVolume(_muted ? 0 : 1);
    final other = _playing;
    if (other != null && !identical(other, this)) other._ctrl?.pause();
    _playing = this;
    if (!_loop &&
        c.value.duration > Duration.zero &&
        c.value.position >= c.value.duration) {
      await c.seekTo(Duration.zero);
    }
    await c.play();
    if (mounted) setState(() {});
  }

  void _pause() {
    final c = _ctrl;
    if (c != null && c.value.isPlaying) c.pause();
    if (identical(_playing, this)) _playing = null;
  }

  @override
  void didUpdateWidget(PostAudioRow old) {
    super.didUpdateWidget(old);
    if (old.loop != widget.loop && _loop != widget.loop) {
      _loop = widget.loop;
      _ctrl?.setLooping(_loop);
    }
    // A new file (the composer swapped the track): drop the old player. A
    // URL arriving next to the same bytes (the upload landed) is not one:
    // the row keeps playing the local file.
    final newBytes = !identical(old.bytes, widget.bytes);
    final newUrl = widget.bytes == null && old.url != widget.url;
    if (newBytes || newUrl) {
      _disposeController();
      if (widget.eager) _open();
    }
  }

  @override
  void dispose() {
    _playback?.removeListener(_syncPlayback);
    _playback?.scrollTick.removeListener(_measure);
    final id = widget.playbackId;
    if (id != null) _playback?.forget(id);
    appRouteObserver.unsubscribe(this);
    _bars.dispose();
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    if (identical(_playing, this)) _playing = null;
    final c = _ctrl;
    _ctrl = null;
    _opening = null;
    c?.removeListener(_onTick);
    c?.dispose();
  }

  /// Open the file once. Local bytes go to the temp dir first (video_player
  /// reads files and URLs, not memory).
  Future<void> _open() {
    return _opening ??= () async {
      VideoPlayerController c;
      try {
        final url = widget.url;
        final bytes = widget.bytes;
        if (bytes != null && !kIsWeb) {
          final dir = await getTemporaryDirectory();
          final name = widget.filename ?? 'audio';
          final ext = name.contains('.') ? name.split('.').last : 'bin';
          final file = File(
              '${dir.path}${Platform.pathSeparator}par_${Object.hash(name, bytes.length)}.$ext');
          if (!await file.exists()) {
            await file.writeAsBytes(bytes, flush: true);
          }
          c = VideoPlayerController.file(file);
        } else if (url != null) {
          c = VideoPlayerController.networkUrl(Uri.parse(url));
        } else {
          throw StateError('no audio source yet');
        }
        await c.initialize();
      } catch (_) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      if (!mounted) {
        c.dispose();
        return;
      }
      await c.setLooping(_loop);
      await c.setVolume(_muted ? 0 : 1);
      c.addListener(_onTick);
      setState(() => _ctrl = c);
      final d = c.value.duration;
      if (d > Duration.zero) widget.onDuration?.call(d);
    }();
  }

  void _onTick() {
    if (!mounted) return;
    final c = _ctrl;
    if (c == null) return;
    if (c.value.isPlaying && !_bars.isAnimating) _bars.repeat();
    if (!c.value.isPlaying && _bars.isAnimating) _bars.stop();
    setState(() {});
  }

  Future<void> _togglePlay() async {
    if (_failed) return;
    await _open();
    final c = _ctrl;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
      if (identical(_playing, this)) _playing = null;
    } else {
      // A tap on a waiting row claims the list's slot, like a video tile's
      // poster tap; the slot's own sync then plays it. Nothing to do here.
      final id = widget.playbackId;
      final playback = _playback;
      if (id != null && playback != null && playback.activeId != id) {
        playback.claim(id);
        return;
      }
      final other = _playing;
      if (other != null && !identical(other, this)) other._ctrl?.pause();
      _playing = this;
      // At the end of a non-looping track, play again from the top.
      if (!_loop &&
          c.value.duration > Duration.zero &&
          c.value.position >= c.value.duration) {
        await c.seekTo(Duration.zero);
      }
      await c.play();
    }
  }

  void _toggleLoop() {
    setState(() => _loop = !_loop);
    _ctrl?.setLooping(_loop);
    widget.onLoopChanged?.call(_loop);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _ctrl?.setVolume(_muted ? 0 : 1);
    // The choice travels with the list's slot (the video pill does the same).
    _playback?.setMuted(_muted);
  }

  Future<void> _seekTo(double fraction) async {
    await _open();
    final c = _ctrl;
    if (c == null) return;
    final d = c.value.duration;
    if (d <= Duration.zero) return;
    await c.seekTo(d * fraction.clamp(0.0, 1.0));
  }

  static String _fmt(Duration d) {
    final s = d.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = h > 0 ? m.toString().padLeft(2, '0') : m.toString();
    return '${h > 0 ? '$h:' : ''}$mm:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final fg = PostAudioRow.foregroundOn(color);
    final dim = color.withValues(alpha: 0.6);
    final playing = _isPlaying;
    final total = _duration;
    final frac = _scrub ??
        (total > Duration.zero
            ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
            : 0.0);
    final shown = _scrub != null ? total * _scrub! : _position;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Play / pause: a disc filled with the colour.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _togglePlay,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: _opening != null && _ctrl == null && !_failed
                ? Padding(
                    padding: const EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: fg),
                  )
                : Icon(
                    _failed
                        ? Icons.error_outline_rounded
                        : playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                    size: 20,
                    color: fg,
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (playing) ...[
                    const SizedBox(width: 6),
                    _LiveBars(animation: _bars, color: color),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _time(_fmt(shown), dim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ScrubLine(
                      fraction: frac,
                      color: color,
                      onStart: (f) => setState(() => _scrub = f),
                      onUpdate: (f) => setState(() => _scrub = f),
                      onEnd: (f) {
                        setState(() => _scrub = null);
                        _seekTo(f);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  _time(_fmt(total), dim),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        VideoGlassButton(
          icon: Icons.repeat_rounded,
          size: 28,
          iconSize: 15,
          color: _loop ? color : dim,
          slashed: !_loop,
          onTap: _toggleLoop,
        ),
        const SizedBox(width: 6),
        VideoGlassButton(
          icon: _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 28,
          iconSize: 15,
          color: _muted ? dim : color,
          onTap: _toggleMute,
        ),
        if (widget.onRemove != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onRemove,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.close_rounded, size: 16, color: dim),
            ),
          ),
        ],
      ],
    );
  }

  Widget _time(String s, Color c) => Text(
        s,
        style: TextStyle(
          color: c,
          fontSize: 10.5,
          height: 1,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

/// Four small bars bouncing while the track plays.
class _LiveBars extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  const _LiveBars({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Container(
                width: 2.5,
                // Each bar on its own phase of one sine.
                height: 4 + 8 * (0.5 + 0.5 * math.sin((t + i * 0.2) * 2 * math.pi)),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

}

/// The 2 px line with its knob; the touch strip is 16 px tall so a finger
/// can find it. Drag or tap to seek.
class _ScrubLine extends StatelessWidget {
  final double fraction;
  final Color color;
  final ValueChanged<double> onStart;
  final ValueChanged<double> onUpdate;
  final ValueChanged<double> onEnd;

  const _ScrubLine({
    required this.fraction,
    required this.color,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      double frac(Offset p) => w <= 0 ? 0 : (p.dx / w).clamp(0.0, 1.0);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => onStart(frac(d.localPosition)),
        onTapUp: (d) => onEnd(frac(d.localPosition)),
        onHorizontalDragStart: (d) => onStart(frac(d.localPosition)),
        onHorizontalDragUpdate: (d) => onUpdate(frac(d.localPosition)),
        onHorizontalDragEnd: (_) => onEnd(fraction),
        child: SizedBox(
          height: 16,
          child: CustomPaint(
            painter: _ScrubPainter(fraction: fraction, color: color),
          ),
        ),
      );
    });
  }
}

class _ScrubPainter extends CustomPainter {
  final double fraction;
  final Color color;
  const _ScrubPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final track = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), track);
    final x = size.width * fraction;
    if (x > 0) canvas.drawLine(Offset(0, y), Offset(x, y), fill);
    canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ScrubPainter old) =>
      old.fraction != fraction || old.color != color;
}
