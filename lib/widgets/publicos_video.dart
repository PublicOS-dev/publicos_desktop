import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_video/zero_cached_video.dart';

/// Settings-aware wrapper around [ZeroCachedVideo].
///
/// Resolves the auto-load threshold from `PublicOSSettings` per-instance so
/// `zero_cached_video` stays free of project knowledge. Use this everywhere
/// in the client; never construct `ZeroCachedVideo` directly.
class PublicOSVideo extends StatefulWidget {
  final String videoUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? poster;
  final bool autoplay;
  final bool loop;
  final bool startMuted;
  final bool showBuiltInPlayPause;

  /// External pause signal — pass-through to [ZeroCachedVideo.paused]. When
  /// true, the underlying controller is force-paused without releasing the
  /// codec; resumes on flip back to false only if [autoplay] is true.
  final bool paused;
  final Widget Function(BuildContext, dynamic)? controlsBuilder;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  /// Override the threshold from settings. Useful for full-screen viewers
  /// where the user already opted into the load (force `double.infinity`).
  final double? thresholdOverrideMb;

  /// Pass-through to [ZeroCachedVideo.mixWithOthers]: the player does not
  /// take audio focus. Inline muted autoplay tiles set it; the focused
  /// overlay keeps the default and takes focus like any video app.
  final bool mixWithOthers;

  /// Pass-through to [ZeroCachedVideo.initialPosition]: where playback
  /// starts once the controller is ready (a feed tile resuming where it was
  /// when it lost the playback slot).
  final Duration? initialPosition;

  const PublicOSVideo({
    super.key,
    required this.videoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.poster,
    this.autoplay = false,
    this.loop = false,
    this.startMuted = false,
    this.showBuiltInPlayPause = true,
    this.paused = false,
    this.controlsBuilder,
    this.placeholder,
    this.errorWidget,
    this.thresholdOverrideMb,
    this.mixWithOthers = false,
    this.initialPosition,
  });

  @override
  State<PublicOSVideo> createState() => _PublicOSVideoState();
}

class _PublicOSVideoState extends State<PublicOSVideo> {
  double? _threshold;

  @override
  void initState() {
    super.initState();
    if (widget.thresholdOverrideMb != null) {
      _threshold = widget.thresholdOverrideMb;
    } else {
      _loadThreshold();
    }
  }

  Future<void> _loadThreshold() async {
    try {
      final mb = await PublicOSSettings.getVideoAutoloadThresholdMb();
      // Autoplay off (Reading settings) = every video waits for
      // a tap: the same gate a 0 MB threshold gives. A surface that passes
      // [thresholdOverrideMb] (the full-screen viewer) never gets here.
      final autoplay = await PublicOSSettings.getVideoAutoplayInFeed();
      if (!mounted) return;
      setState(() => _threshold = autoplay ? mb.toDouble() : 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _threshold = 35);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_threshold == null) {
      // Brief settings-read delay; show poster (or empty) so layout is stable.
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.poster ?? const SizedBox.shrink(),
      );
    }
    return ZeroCachedVideo(
      videoUrl: widget.videoUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      poster: widget.poster,
      autoLoadThresholdMb: _threshold!,
      autoplay: widget.autoplay,
      loop: widget.loop,
      startMuted: widget.startMuted,
      showBuiltInPlayPause: widget.showBuiltInPlayPause,
      paused: widget.paused,
      controlsBuilder: widget.controlsBuilder == null
          ? null
          : (ctx, controller) => widget.controlsBuilder!(ctx, controller),
      placeholder: widget.placeholder,
      errorWidget: widget.errorWidget,
      mixWithOthers: widget.mixWithOthers,
      initialPosition: widget.initialPosition,
    );
  }
}
