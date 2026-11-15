import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:zero_cached_thumbnail/zero_cached_thumbnail.dart';
import 'package:zero_cached_video/zero_cached_video.dart';

/// A controller-free still frame for a remote video URL.
///
/// Decodes a single JPEG frame via `zero_cached_thumbnail`, reusing
/// `zero_cached_video`'s on-disk cache so the clip is fetched **once** and that
/// one file serves both this poster and later playback (no double download).
/// **No `VideoPlayerController` is ever allocated** — safe to mount many at once
/// in a feed, which is the whole point: a poster tile must not hold a decoder.
///
/// Falls back to a black fill while decoding and on any failure (unsupported
/// platform — web/Linux throw `UnsupportedError` — network, or codec). Matches
/// the chat thumbnail fallback in [ChatVideoBubble].
///
/// **Server poster first:** a video
/// on either door (`/media/…` or `/pedia/…`) tries `<video url>/poster` — a
/// small JPEG the author's app uploaded beside the video — through
/// [ZeroCachedImage], so the frame shows without touching the clip (a private
/// poster is sealed per reader and opened by the fetch hooks). Only a 404
/// (old videos, other servers) falls back to the local decode below.
///
/// Cost note (the fallback): `ThumbnailSource.path` needs a local file, so the first decode
/// pulls the **full** clip to disk via `ZeroVideoCacheManager.getFilePath`.
/// That's shared with playback (good when the user expands) but is eager work
/// for a poster the user may never open.
class VideoUrlThumbnail extends StatefulWidget {
  final String videoUrl;
  final BoxFit fit;

  const VideoUrlThumbnail({
    super.key,
    required this.videoUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<VideoUrlThumbnail> createState() => _VideoUrlThumbnailState();
}

class _VideoUrlThumbnailState extends State<VideoUrlThumbnail> {
  Uint8List? _jpeg;

  /// True once the server poster is known missing (or never applies), so the
  /// local-decode fallback runs.
  bool _useFallback = false;

  // Both doors: a /pedia/ poster rides the fetch hooks (401 challenge ->
  // envelope -> sealed body opened), exactly like the private video.
  bool get _hasServerPoster =>
      widget.videoUrl.contains('/media/') || widget.videoUrl.contains('/pedia/');

  @override
  void initState() {
    super.initState();
    _useFallback = !_hasServerPoster;
    if (_useFallback) _load();
  }

  @override
  void didUpdateWidget(VideoUrlThumbnail old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      _jpeg = null;
      _useFallback = !_hasServerPoster;
      if (_useFallback) _load();
    }
  }

  void _posterMissing() {
    if (_useFallback || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _useFallback) return;
      setState(() => _useFallback = true);
      _load();
    });
  }

  Future<void> _load() async {
    try {
      // Reuse the player's cached file (downloads on a miss, returns the local
      // path on a hit) so the clip is fetched once for both poster + playback.
      final path =
          await ZeroVideoCacheManager.instance.getFilePath(widget.videoUrl);
      final bytes = await ZeroCachedThumbnail.bytes(
        ThumbnailSource.path(path, cacheKey: widget.videoUrl),
      );
      if (!mounted) return;
      setState(() => _jpeg = bytes);
    } catch (_) {
      // Keep the black fallback — unsupported platform / network / codec.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_useFallback) {
      return ZeroCachedImage(
        imageUrl: PublicOSSsp.posterUrlFor(widget.videoUrl),
        fit: widget.fit,
        placeholder: (_, __) => const ColoredBox(color: Colors.black),
        errorWidget: (_, __, ___) {
          _posterMissing();
          return const ColoredBox(color: Colors.black);
        },
      );
    }
    final jpeg = _jpeg;
    if (jpeg == null) return const ColoredBox(color: Colors.black);
    return Image.memory(
      jpeg,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
    );
  }
}
