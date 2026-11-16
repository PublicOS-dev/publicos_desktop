import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/post_playback_scope.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:video_player/video_player.dart';

/// Bottom video controls — play/pause + scrubber + position/duration + loop +
/// mute + save. Shared by the full-screen [MediaOverlay] and the inline feed
/// player ([TappableMedia]'s video branch) so both surfaces handle video
/// identically.
///
/// Two arrangements, branched in `build`:
/// - **Overlay (default)**: the glass capsule — one row, scrubber takes the
///   slack, 12px in from the edges, clears the home indicator.
/// - **Compact (`compact: true`, the inline post player)**: no container,
///   the controls laid out over the whole tile. A **centered glass play
///   disc** while the clip is
///   not playing and nothing while it plays (a tap on the video pauses, the
///   disc appears; tap the disc, it goes); **expand top-right** when the
///   host passes [onExpand] (a post card draws its own corner pill instead
///   and reaches the player through an `ExpandHandle`); **mute bottom-right,
///   always, with loop to its left while paused**; the time bottom-left
///   under a soft shade, **shown for a second at every play or pause and
///   then faded out**; and an **edge-to-edge 2px progress line
///   flush with the tile's bottom edge**, dimmer than the overlay's. While
///   playing there is no handle; the dot appears only while a finger is down
///   on the 16px strip above the edge ([_EdgeScrubber.hitHeight]). The
///   discs are the profile pills' frosted glass (blur 10, black 30 %), round.
///   Hand-rolled instead of a `Slider` so the line can reach the tile's
///   edges and the touch strip is ours to size. [VideoGlassButton] is the
///   disc, public so the post card draws the same one.
///
/// Pass it to a [PublicOSVideo] / [PublicOSBytesVideo] `controlsBuilder`. It
/// paints only near the bottom edge, so the player's central tap-to-toggle
/// (`showBuiltInPlayPause`) stays active. Mute/loop are persisted via
/// `PublicOSSettings` (UI-layer keys, not SDK-typed wrappers). The host owns
/// the actual save (it differs for url / bytes / image), surfaced via [onSave]
/// + [isSaving]; pass `onSave: null` to hide the save button entirely.
class VideoControlsPill extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onSave;
  final bool isSaving;

  /// Compact only: the expand-to-fullscreen button. Null hides it.
  final VoidCallback? onExpand;

  /// Container-less layout for the inline post player (see the class doc).
  /// The full-width focused overlay keeps the default capsule.
  final bool compact;


  const VideoControlsPill({
    super.key,
    required this.controller,
    this.onSave,
    this.onExpand,
    this.isSaving = false,
    this.compact = false,
  });

  @override
  State<VideoControlsPill> createState() => _VideoControlsPillState();
}

class _VideoControlsPillState extends State<VideoControlsPill> {
  // While the user is dragging, hold the slider's thumb position locally
  // and DO NOT call seekTo on every change — flushing the HEVC decoder on
  // each tick stalls playback (seen as `MediaCodec discarded an unknown
  // buffer` + `flushed work; ignored` spam from the codec).
  double? _scrubMs;
  bool _wasPlayingBeforeScrub = false;

  // Settings keys are UI-layer concerns — keep them local. Core only owns
  // the generic getSetting/setSetting machinery (per-session-address Record
  // table); typed wrappers like getVideoOverlayMuted/Loop don't belong in
  // the SDK.
  static const _kMuteKey = 'video_overlay_muted';
  static const _kLoopKey = 'video_overlay_loop';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPlayStateTick);
    _showTimeBriefly();
    _applyPersistedPrefs();
  }

  @override
  void didUpdateWidget(covariant VideoControlsPill old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.removeListener(_onPlayStateTick);
      widget.controller.addListener(_onPlayStateTick);
    }
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    widget.controller.removeListener(_onPlayStateTick);
    super.dispose();
  }

  // The time label: on while paused; on playback it stays two seconds,
  // then fades.
  bool _timeShown = true;
  bool? _wasPlaying;
  Timer? _timeTimer;

  void _onPlayStateTick() {
    final playing = widget.controller.value.isPlaying;
    if (playing == _wasPlaying) return;
    _wasPlaying = playing;
    if (playing) {
      _showTimeBriefly();
    } else {
      _holdTime();
    }
  }

  void _holdTime() {
    _timeTimer?.cancel();
    if (mounted && !_timeShown) setState(() => _timeShown = true);
  }

  void _showTimeBriefly() {
    _timeTimer?.cancel();
    if (mounted && !_timeShown) setState(() => _timeShown = true);
    _timeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _timeShown = false);
    });
  }

  Future<bool> _readBoolPref(String key) async {
    try {
      final record = await PublicOSSettings.getSetting(key);
      return record?.value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeBoolPref(String key, bool value) async {
    try {
      final record = Record.asSettings(
        key: key,
        value: value.toString(),
        isExpired: false,
        isSystem: true,
      );
      await PublicOSSettings.setSetting(key, record);
    } catch (_) {
      // Swallow — persistence is best-effort, the in-session toggle still
      // applied to the controller.
    }
  }

  Future<void> _applyPersistedPrefs() async {
    final results = await Future.wait([
      _readBoolPref(_kMuteKey),
      _readBoolPref(_kLoopKey),
    ]);
    if (!mounted) return;
    final muted = results[0];
    final loop = results[1];
    // Only force-mute when the pref says so. We never force-unmute here: an
    // inline feed player starts muted regardless, and stays so until the user
    // taps the volume button.
    if (muted) await widget.controller.setVolume(0.0);
    if (loop) await widget.controller.setLooping(true);
  }

  Future<void> _toggleMute(bool currentlyMuted) async {
    final next = !currentlyMuted;
    await widget.controller.setVolume(next ? 0.0 : 1.0);
    // The next inline winner on this list starts with the same choice.
    // No scope on the focused screen: nothing to tell.
    if (mounted) PostPlaybackScope.read(context)?.setMuted(next);
    await _writeBoolPref(_kMuteKey, next);
  }

  Future<void> _toggleLoop(bool currentlyLooping) async {
    final next = !currentlyLooping;
    await widget.controller.setLooping(next);
    await _writeBoolPref(_kLoopKey, next);
  }

  void _onScrubStart(double v) {
    // Already scrubbing (the edge scrubber reports start on finger-down and
    // again when that turns into a drag): keep the recorded play state, just
    // move the thumb.
    if (_scrubMs != null) {
      setState(() => _scrubMs = v);
      return;
    }
    final value = widget.controller.value;
    // Resume after release if the controller was actively playing OR if it
    // had completed (user scrubbed back from the end to rewatch — they
    // clearly want playback to continue from the new position).
    _wasPlayingBeforeScrub = value.isPlaying || value.isCompleted;
    if (value.isPlaying) widget.controller.pause();
    setState(() => _scrubMs = v);
  }

  void _onScrubChanged(double v) {
    setState(() => _scrubMs = v);
  }

  Future<void> _onScrubEnd(double v) async {
    await widget.controller.seekTo(Duration(milliseconds: v.toInt()));
    if (_wasPlayingBeforeScrub) widget.controller.play();
    if (!mounted) return;
    setState(() => _scrubMs = null);
  }

  /// The finger went down on the strip but the gesture was taken by someone
  /// else (the feed scrolled): no seek, just resume what was playing.
  void _onScrubCancel() {
    if (_scrubMs == null) return;
    if (_wasPlayingBeforeScrub) widget.controller.play();
    setState(() => _scrubMs = null);
  }

  Future<void> _togglePlay(VideoPlayerValue value) async {
    final controller = widget.controller;
    if (value.isPlaying) {
      await controller.pause();
    } else {
      // After natural completion the position sits at the end of the file;
      // play() alone has nothing to decode, so seek back to 0 first (replay).
      if (value.isCompleted) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }
  }

  /// [box] is the tap target's side, [iconSize] the glyph (defaults to the
  /// overlay's Material 36/22). Compact keeps the 28px box and draws an 18px
  /// glyph in it.
  IconButton _iconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.white,
    double box = 36,
    double? iconSize,
    List<Shadow>? shadows,
  }) {
    return IconButton(
      iconSize: iconSize ?? box - 14,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: box, minHeight: box),
      color: color,
      icon: Icon(icon, shadows: shadows),
      onPressed: onPressed,
    );
  }

  Widget? _saveButton({
    double box = 36,
    double? iconSize,
    List<Shadow>? shadows,
  }) {
    if (widget.onSave == null) return null;
    return SizedBox(
      width: box,
      height: box,
      child: widget.isSaving
          ? const Center(
              child: PhigitalLoadingWidget(size: 16, showShadows: false),
            )
          : _iconButton(
              icon: Icons.save_alt,
              onPressed: widget.onSave!,
              box: box,
              iconSize: iconSize,
              shadows: shadows,
            ),
    );
  }

  String _timeLabel(VideoPlayerValue value) {
    final pos = _scrubMs != null
        ? Duration(milliseconds: _scrubMs!.toInt())
        : value.position;
    return '${_fmt(pos)} / ${_fmt(value.duration)}';
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _buildCompact() : _buildOverlay();
  }

  /// A soft shade under the compact time label so it reads on a bright
  /// frame. Blurred, no offset: a crisp shadow reads as a border.
  static const List<Shadow> _kCompactShade = [
    Shadow(color: Color(0x80000000), blurRadius: 6),
  ];

  /// Inset of every compact control from the tile's edges.
  static const double _kCompactInset = 8;

  /// Inline post player: controls over the whole tile, the progress line
  /// flush with the bottom edge. Nothing here absorbs a tap it does not own,
  /// so the player's tap-to-toggle keeps working around the discs.
  Widget _buildCompact() {
    final controller = widget.controller;
    return Positioned.fill(
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (ctx, value, _) {
          if (!value.isInitialized) return const SizedBox.shrink();
          final maxMs = value.duration.inMilliseconds == 0
              ? 1
              : value.duration.inMilliseconds;
          final posMs = value.position.inMilliseconds
              .clamp(0, maxMs)
              .toDouble();
          final shownMs = (_scrubMs ?? posMs).clamp(0.0, maxMs.toDouble());
          final muted = value.volume == 0.0;

          // Material(transparency) keeps an ancestor Material in every
          // context: the pill is built inside ZeroCachedVideo's
          // controlsBuilder and, during the Hero expand flight, sits directly
          // under MaterialApp with no Material between.
          return Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                // Not playing: one disc in the middle. Playing: nothing, the
                // video is the thing.
                if (!value.isPlaying)
                  Center(
                    child: VideoGlassButton(
                      icon: Icons.play_arrow_rounded,
                      size: 56,
                      iconSize: 32,
                      onTap: () => _togglePlay(value),
                    ),
                  ),
                // Mute bottom-right whatever the play state; loop joins it on
                // its left only while paused.
                Positioned(
                  right: _kCompactInset,
                  // 8 up: clear of the 28 px scrub strip.
                  bottom: _kCompactInset + 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!value.isPlaying) ...[
                        VideoGlassButton(
                          icon: Icons.repeat_rounded,
                          // Off = the glyph struck through; the slash
                          // carries the state, so one colour for both.
                          slashed: !value.isLooping,
                          onTap: () => _toggleLoop(value.isLooping),
                        ),
                        const SizedBox(width: VideoGlassButton.gap),
                      ],
                      VideoGlassButton(
                        icon: muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        onTap: () => _toggleMute(muted),
                      ),
                    ],
                  ),
                ),
                // Time, bottom-left, just above the line. Shown while paused
                // and while scrubbing; on playback it stays two seconds, then
                // fades.
                Positioned(
                  left: _kCompactInset,
                  bottom: 10,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _timeShown || _scrubMs != null ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _timeLabel(value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                          shadows: _kCompactShade,
                        ),
                      ),
                    ),
                  ),
                ),
                // Expand, top-right, for hosts without a corner pill of
                // their own.
                if (widget.onExpand != null)
                  Positioned(
                    right: _kCompactInset,
                    top: _kCompactInset,
                    child: VideoGlassButton(
                      icon: Icons.open_in_full_rounded,
                      iconSize: 18,
                      onTap: widget.onExpand!,
                    ),
                  ),
                // The line, under everything else so the discs win where
                // they overlap its strip.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _EdgeScrubber(
                    fraction: shownMs / maxMs,
                    scrubbing: _scrubMs != null,
                    onStart: (f) => _onScrubStart(f * maxMs),
                    onChanged: (f) => _onScrubChanged(f * maxMs),
                    onEnd: (f) => _onScrubEnd(
                      f != null ? f * maxMs : (_scrubMs ?? posMs),
                    ),
                    onCancel: _onScrubCancel,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Full-screen overlay: the glass capsule, one row. A plain box: the
  /// overlay places it in its controls row.
  Widget _buildOverlay() {
    final controller = widget.controller;
    // Absorb taps/drags so nothing under the pill (the overlay's backdrop
    // tap-to-dismiss) fires when the user grabs the scrubber or hits a
    // button in the capsule's own padding.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onPanDown: (_) {},
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (ctx, value, _) {
          if (!value.isInitialized) return const SizedBox.shrink();
          final dur = value.duration;
          final maxMs = dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds;
          final posMs = value.position.inMilliseconds
              .clamp(0, maxMs)
              .toDouble();
          final muted = value.volume == 0.0;

          final slider = SliderTheme(
            data: SliderTheme.of(ctx).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 14,
              ),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              min: 0,
              max: maxMs.toDouble(),
              value: (_scrubMs ?? posMs).clamp(0, maxMs.toDouble()),
              onChangeStart: _onScrubStart,
              onChanged: _onScrubChanged,
              onChangeEnd: _onScrubEnd,
            ),
          );

          final timeText = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _timeLabel(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          );

          final saveButton = _saveButton();

          // Material(transparency) gives the Slider (a Material widget) an
          // ancestor Material in every context — the pill is built inside
          // ZeroCachedVideo's controlsBuilder and, during the Hero expand
          // flight, sits directly under MaterialApp with no Material between
          // (the "No Material widget found" crash).
          return Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                child: Row(
                  children: [
                    _iconButton(
                      icon: value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      onPressed: () => _togglePlay(value),
                    ),
                    Expanded(child: slider),
                    timeText,
                    _iconButton(
                      icon: Icons.repeat,
                      // Same icon for both states, color signals on/off —
                      // matches the user's "toggle on a single icon" ask.
                      color: value.isLooping
                          ? Colors.white
                          : Colors.white54,
                      onPressed: () => _toggleLoop(value.isLooping),
                    ),
                    _iconButton(
                      icon: muted ? Icons.volume_off : Icons.volume_up,
                      onPressed: () => _toggleMute(muted),
                    ),
                    if (saveButton != null) saveButton,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _fmt(Duration d) {
    final s = d.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}

/// A round frosted-glass button over media: the profile pills' glass (blur
/// 10, black 30 %) in a circle with a white glyph. The inline player's play,
/// loop, mute and expand discs, and the hero pager's expand disc on a picture
/// page, are all this one widget, so they match to the pixel.
class VideoGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color color;

  /// Strike the glyph through, the way Material's own "off" icons are drawn
  /// (a slash with a carved gap): the loop button's off state, since there
  /// is no slashed repeat glyph in the set, and a colour change alone is
  /// not enough.
  final bool slashed;

  /// Vertical gap between two stacked discs.
  static const double gap = 8;

  /// The disc's default diameter; hosts that line things up with the discs
  /// (the tall-hero rail) size their boxes to it.
  static const double defaultSize = 36;

  const VideoGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = defaultSize,
    this.iconSize = 20,
    this.color = Colors.white,
    this.slashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // The disc is the target, not the glyph: a DecoratedBox does not
      // hit-test itself, so the detector claims the whole circle.
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.30),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: slashed
                    ? SlashedIcon(icon, size: iconSize, color: color)
                    : Icon(icon, size: iconSize, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon struck through from top-left to bottom-right, one plain stroke
/// in the glyph's colour.
class SlashedIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const SlashedIcon(
    this.icon, {
    super.key,
    required this.size,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        foregroundPainter: _SlashPainter(color: color),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  final Color color;
  const _SlashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final a = Offset(size.width * 0.18, size.height * 0.18);
    final b = Offset(size.width * 0.82, size.height * 0.82);
    final w = size.width / 11;
    // Just the stroke: a carved gap beside it reads as a shadow.
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SlashPainter old) => old.color != color;
}

/// A frosted-glass capsule holding a few controls in one row: the same
/// glass as [VideoGlassButton], 40 px tall, pill-shaped. The post card's
/// top-right corner on a hero (counter, expand, the post menu) is one of
/// these; [item] is a 36 px tap cell for an icon inside it.
class VideoGlassPill extends StatelessWidget {
  final List<Widget> children;

  const VideoGlassPill({super.key, required this.children});

  static const double height = 40;

  static Widget item({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 20,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: height,
        height: height,
        child: Center(child: Icon(icon, size: iconSize, color: color)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: SizedBox(
            height: height,
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

/// The compact layout's scrubber: an edge-to-edge 2px progress line flush
/// with the tile's bottom edge, inside a touch strip [hitHeight] tall. While
/// playing nothing but the line is drawn; the dot appears only while a finger
/// is down on the strip. Reports positions as a 0..1 fraction of the width.
///
/// Gestures: finger down shows the dot where it landed (`onStart`), lifting
/// seeks there (`onEnd(f)`); a **horizontal** drag scrubs (`onChanged`, then
/// `onEnd(null)` = commit the last reported position). Only horizontal drags
/// are claimed, so the feed's vertical scroll still works over the strip: when
/// the scroll wins, the tap is cancelled and `onCancel` restores playback with
/// no seek. A tap that turns into a drag also cancels first and then starts
/// the drag; that cancel is deferred one frame and dropped when the drag
/// start arrives, so the host sees one continuous scrub.
class _EdgeScrubber extends StatefulWidget {
  final double fraction;
  final bool scrubbing;
  final ValueChanged<double> onStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double?> onEnd;
  final VoidCallback onCancel;

  // 28, tall enough to grab while dragging on a video in the list. The
  // controls row still wins on its own footprint.
  static const double hitHeight = 28;
  static const double trackHeight = 2;
  static const double thumbRadius = 5;

  const _EdgeScrubber({
    required this.fraction,
    required this.scrubbing,
    required this.onStart,
    required this.onChanged,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  State<_EdgeScrubber> createState() => _EdgeScrubberState();
}

class _EdgeScrubberState extends State<_EdgeScrubber> {
  bool _cancelPending = false;

  void _deferCancel() {
    _cancelPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cancelPending) return;
      _cancelPending = false;
      if (mounted) widget.onCancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        double frac(Offset local) =>
            w <= 0 ? 0 : (local.dx / w).clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => widget.onStart(frac(d.localPosition)),
          onTapUp: (d) => widget.onEnd(frac(d.localPosition)),
          onTapCancel: _deferCancel,
          onHorizontalDragStart: (d) {
            _cancelPending = false;
            widget.onStart(frac(d.localPosition));
          },
          onHorizontalDragUpdate: (d) =>
              widget.onChanged(frac(d.localPosition)),
          onHorizontalDragEnd: (_) => widget.onEnd(null),
          onHorizontalDragCancel: widget.onCancel,
          child: SizedBox(
            height: _EdgeScrubber.hitHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _EdgeScrubberPainter(
                fraction: widget.fraction,
                scrubbing: widget.scrubbing,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EdgeScrubberPainter extends CustomPainter {
  final double fraction;
  final bool scrubbing;

  const _EdgeScrubberPainter({required this.fraction, required this.scrubbing});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // Flush with the bottom edge: the 2px line's lower half is the edge.
    final cy = size.height - _EdgeScrubber.trackHeight / 2;
    final x = (fraction * w).clamp(0.0, w);

    // Dimmer than the overlay's slider: the line marks, it does not compete
    // with the frame.
    final inactive = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = _EdgeScrubber.trackHeight;
    final active = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = _EdgeScrubber.trackHeight;

    canvas.drawLine(Offset(0, cy), Offset(w, cy), inactive);
    canvas.drawLine(Offset(0, cy), Offset(x, cy), active);

    if (scrubbing) {
      const r = _EdgeScrubber.thumbRadius;
      // Keep the whole dot inside the width at either end.
      canvas.drawCircle(
        Offset(x.clamp(r, w - r), cy),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_EdgeScrubberPainter old) =>
      old.fraction != fraction || old.scrubbing != scrubbing;
}
