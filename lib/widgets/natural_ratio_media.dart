import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/media_aspect_cache.dart';
import 'package:publicos_desktop/widgets/media_overlay.dart' show VideoHandoff;
import 'package:publicos_desktop/widgets/tappable_media.dart';
import 'package:video_player/video_player.dart';

/// Renders a media item at its natural aspect ratio. Sources are mutually
/// exclusive: pass exactly one of [mediaUrl], [imageBytes], [videoBytes].
///
/// Sizing rules (in order):
/// - If [width] is set, that width is used; otherwise the LayoutBuilder's
///   maxWidth.
/// - height = width / ratio.
/// - If [maxHeight] is set and the natural height exceeds it, height is
///   clamped to maxHeight and width is scaled DOWN proportionally so the
///   ratio is preserved (no letterboxing — the box itself takes the
///   correct shape).
///
/// While the ratio probe is in flight, renders a square skeleton (width ×
/// width) with a centered play affordance — same surface tone as the rest
/// of the card so it reads as "media incoming" rather than "loading state".
/// Size and opacity transition over 150ms once the ratio is known. URL
/// probes go through [MediaAspectCache], so a feed-load prefetch can warm
/// the cache and the first paint lands at the right shape.
class NaturalRatioMedia extends StatefulWidget {
  final String? mediaUrl;
  final Uint8List? imageBytes;
  final Uint8List? videoBytes;
  final String? filename;
  final String heroTag;
  final double? width;
  /// When set (and [width] is null), the media renders at its natural width but
  /// never wider than [maxWidth] — and never upscaled beyond the source's own
  /// pixel width. Used for stickers (natural size, capped at a screen %).
  final double? maxWidth;
  final double? maxHeight;
  /// When the natural height exceeds [maxHeight], keep the full width and crop
  /// to fill (cover) instead of shrinking the width to preserve the ratio. Used
  /// where the media must span a fixed frame, e.g. a captioned image filling
  /// its chat bubble. Default false: the box takes the media's own shape.
  final bool fillWidth;
  /// When the natural height falls under [minHeight], the box grows to it at
  /// the same width and the media is CONTAINED on black (letterboxed), so a
  /// very wide clip still has room for its controls. Default null: the box
  /// is as short as the media.
  final double? minHeight;
  /// The box keeps the full width even when [maxHeight] caps the height, and
  /// the media is CONTAINED, centred, on black: the pillarbox. A portrait clip
  /// in a wide reading column sits in the middle with black stripes either
  /// side instead of hugging the left edge (desktop lone videos). A clip
  /// that already fills the width looks the same as cover.
  /// Default false.
  final bool contain;
  /// A video's expand, reachable by the host ([TappableMedia.expandHandle]).
  final ExpandHandle? expandHandle;
  /// The post's header for the overlay ([TappableMedia.overlayHeader]).
  final Widget? overlayHeader;
  /// A video's starting state ([TappableMedia.videoHandoff]).
  final VideoHandoff? videoHandoff;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  const NaturalRatioMedia({
    super.key,
    this.mediaUrl,
    this.imageBytes,
    this.videoBytes,
    this.filename,
    required this.heroTag,
    this.width,
    this.maxWidth,
    this.maxHeight,
    this.fillWidth = false,
    this.minHeight,
    this.contain = false,
    this.expandHandle,
    this.overlayHeader,
    this.videoHandoff,
    this.borderRadius,
    this.errorBuilder,
    this.loadingBuilder,
  }) : assert(
          (mediaUrl != null ? 1 : 0) +
                  (imageBytes != null ? 1 : 0) +
                  (videoBytes != null ? 1 : 0) ==
              1,
          'Provide exactly one of mediaUrl, imageBytes, or videoBytes.',
        );

  @override
  State<NaturalRatioMedia> createState() => _NaturalRatioMediaState();
}

class _NaturalRatioMediaState extends State<NaturalRatioMedia> {
  static const Duration _animDuration = Duration(milliseconds: 150);
  double? _aspectRatio;
  double? _naturalWidthPx; // source pixel width, captured at probe time

  @override
  void initState() {
    super.initState();
    // Synchronous cache hit → render at the right shape on first frame,
    // skip the skeleton entirely.
    if (widget.mediaUrl != null) {
      final cached = MediaAspectCache.get(widget.mediaUrl!);
      if (cached != null) {
        _aspectRatio = cached;
        return;
      }
    }
    _resolveRatio();
  }

  Future<void> _resolveRatio() async {
    if (widget.mediaUrl != null) {
      final ratio = await MediaAspectCache.probe(widget.mediaUrl!);
      if (mounted && ratio != null) {
        setState(() => _aspectRatio = ratio);
      }
      return;
    }
    if (widget.imageBytes != null) {
      _probeFromImageBytes(widget.imageBytes!);
      return;
    }
    if (widget.videoBytes != null) {
      await _probeFromVideoBytes(widget.videoBytes!);
      return;
    }
  }

  void _probeFromImageBytes(Uint8List bytes) {
    final provider = MemoryImage(bytes);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          final ar = info.image.width / info.image.height;
          if (ar > 0) {
            setState(() {
              _aspectRatio = ar;
              _naturalWidthPx = info.image.width.toDouble();
            });
          }
        }
        stream.removeListener(listener);
      },
      onError: (_, __) => stream.removeListener(listener),
    );
    stream.addListener(listener);
  }

  Future<void> _probeFromVideoBytes(Uint8List bytes) async {
    try {
      final tempPath = await _ensureTempFile(bytes, widget.filename);
      final c = VideoPlayerController.file(File(tempPath));
      try {
        await c.initialize();
        final size = c.value.size;
        if (mounted && size.width > 0 && size.height > 0) {
          setState(() => _aspectRatio = size.width / size.height);
        }
      } finally {
        await c.dispose();
      }
    } catch (_) {
      // fall through to default
    }
  }

  /// sha256-keyed temp file. If a file with this digest already exists from
  /// a previous probe / playback (PublicOSBytesVideo uses the same shape),
  /// reuse it instead of rewriting bytes.
  Future<String> _ensureTempFile(Uint8List bytes, String? filename) async {
    final digest = sha256.convert(bytes).toString();
    final dir = await getTemporaryDirectory();
    final ext = filename == null
        ? ''
        : (() {
            final dot = filename.lastIndexOf('.');
            return dot == -1 ? '' : filename.substring(dot).toLowerCase();
          })();
    final path = '${dir.path}/zcv_$digest$ext';
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Base width: explicit [width], else the [maxWidth] cap, else fill.
        // With [maxWidth] set, cap at maxWidth and never upscale past the
        // source's own (logical) width once the probe knows it.
        double baseWidth = widget.width ?? widget.maxWidth ?? constraints.maxWidth;
        if (widget.maxWidth != null) {
          final double naturalLogical = _naturalWidthPx != null
              ? _naturalWidthPx! / MediaQuery.of(context).devicePixelRatio
              : double.infinity;
          if (naturalLogical < baseWidth) baseWidth = naturalLogical;
          if (widget.maxWidth! < baseWidth) baseWidth = widget.maxWidth!;
        }
        if (baseWidth > constraints.maxWidth) baseWidth = constraints.maxWidth;

        // Skeleton phase: square box, surfaceDeep tone, centered play icon.
        // No spinner — it's a placeholder, not a loader.
        if (_aspectRatio == null) {
          return AnimatedContainer(
            duration: _animDuration,
            curve: Curves.easeOutCubic,
            width: baseWidth,
            height: baseWidth,
            decoration: BoxDecoration(
              color: tokens.surfaceDeep,
              borderRadius: widget.borderRadius,
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_outline,
                color: tokens.starkWhite.withValues(alpha: 0.45),
                size: 56,
              ),
            ),
          );
        }

        // Resolved phase: animate to natural aspect, fade media in.
        final ratio = _aspectRatio!;
        var w = baseWidth;
        var h = w / ratio;
        if (widget.maxHeight != null && h > widget.maxHeight!) {
          h = widget.maxHeight!;
          // fillWidth: keep w, TappableMedia covers; contain: keep w, pillarbox.
          if (!widget.fillWidth && !widget.contain) w = h * ratio;
        }
        var letterboxed = widget.contain;
        if (widget.minHeight != null && h < widget.minHeight!) {
          h = widget.minHeight!;
          letterboxed = true;
        }
        return AnimatedContainer(
          duration: _animDuration,
          curve: Curves.easeOutCubic,
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: letterboxed ? Colors.black : null,
            borderRadius: widget.borderRadius,
          ),
          child: AnimatedSwitcher(
            duration: _animDuration,
            child: TappableMedia(
              key: const ValueKey('media'),
              mediaUrl: widget.mediaUrl,
              imageData: widget.imageBytes,
              videoBytes: widget.videoBytes,
              filename: widget.filename,
              heroTag: widget.heroTag,
              width: w,
              height: h,
              fit: letterboxed ? BoxFit.contain : BoxFit.cover,
              expandHandle: widget.expandHandle,
              overlayHeader: widget.overlayHeader,
              videoHandoff: widget.videoHandoff,
              borderRadius: widget.borderRadius,
              errorBuilder: widget.errorBuilder,
              loadingBuilder: widget.loadingBuilder,
            ),
          ),
        );
      },
    );
  }
}
