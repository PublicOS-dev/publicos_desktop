import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:zero_cached_video/zero_cached_video.dart';

/// publicos_client wrapper for [ZeroBytesVideo].
///
/// No settings consultation — bytes are already in memory, so the
/// auto-load gate that `PublicOSVideo` enforces for URL-based videos
/// doesn't apply (we already paid the data cost). Use this for XMTP
/// attachments and any other in-memory video payload.
///
/// Discipline: never construct `ZeroBytesVideo` or `VideoPlayerController`
/// directly in publicos_client — always go through this wrapper (parallel
/// to `PublicOSVideo` for the URL case).
class PublicOSBytesVideo extends StatelessWidget {
  final Uint8List data;
  final String? filename;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool autoplay;
  final bool loop;
  final bool startMuted;
  final bool showBuiltInPlayPause;

  /// External pause signal — pass-through to [ZeroBytesVideo.paused].
  final bool paused;
  final Widget Function(BuildContext, VideoPlayerController)? controlsBuilder;
  final Widget Function(BuildContext)? placeholder;
  final Widget Function(BuildContext, Object)? errorWidget;

  /// Pass-through to [ZeroBytesVideo.mixWithOthers]: the player does not
  /// take audio focus. Inline muted autoplay tiles set it; the focused
  /// overlay keeps the default and takes focus like any video app.
  final bool mixWithOthers;

  const PublicOSBytesVideo({
    super.key,
    required this.data,
    this.filename,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.autoplay = false,
    this.loop = false,
    this.startMuted = false,
    this.showBuiltInPlayPause = true,
    this.paused = false,
    this.controlsBuilder,
    this.placeholder,
    this.errorWidget,
    this.mixWithOthers = false,
  });

  @override
  Widget build(BuildContext context) {
    return ZeroBytesVideo(
      data: data,
      filename: filename,
      width: width,
      height: height,
      fit: fit,
      autoplay: autoplay,
      loop: loop,
      startMuted: startMuted,
      showBuiltInPlayPause: showBuiltInPlayPause,
      paused: paused,
      controlsBuilder: controlsBuilder,
      placeholder: placeholder,
      errorWidget: errorWidget,
      mixWithOthers: mixWithOthers,
    );
  }
}
