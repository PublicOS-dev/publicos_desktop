import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/tappable_media.dart';
import 'package:zero_cached_thumbnail/zero_cached_thumbnail.dart';

/// Thumbnail-first video bubble for the chat list. Decodes a JPEG thumbnail
/// of [videoBytes] via `zero_cached_thumbnail`, paints it with a play
/// overlay. First tap swaps in the real [TappableMedia] player, which
/// autoplays. "Expanded" lives on local State — survives scroll-off via
/// MessageWidget's AutomaticKeepAliveClientMixin, dies when chat_screen
/// disposes (== leaving the conversation).
///
/// [videoAspectCache] is owned by chat_screen state so aspect lookups are
/// shared across bubbles in the same conversation (cheap; saves the JPEG
/// dimension read on repeat measurements of the same message).
class ChatVideoBubble extends StatefulWidget {
  final Uint8List videoBytes;
  final String messageId;
  final String? filename;
  final String heroTag;
  final double width;
  final double maxHeight;
  final BorderRadius? borderRadius;
  final Map<String, double> videoAspectCache;

  const ChatVideoBubble({
    super.key,
    required this.videoBytes,
    required this.messageId,
    required this.heroTag,
    required this.videoAspectCache,
    this.filename,
    this.width = 300,
    this.maxHeight = 300,
    this.borderRadius,
  });

  @override
  State<ChatVideoBubble> createState() => _ChatVideoBubbleState();
}

class _ChatVideoBubbleState extends State<ChatVideoBubble> {
  static const Duration _animDuration = Duration(milliseconds: 150);

  Uint8List? _jpegBytes;
  double? _aspectRatio;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.videoAspectCache[widget.messageId];
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final jpeg = await ZeroCachedThumbnail.bytes(
        ThumbnailSource.bytes(
          widget.videoBytes,
          cacheKey: 'msg_${widget.messageId}',
        ),
      );
      if (!mounted) return;
      // Measure aspect from the JPEG BEFORE committing to state so the
      // bytes + final size land in the same frame. Otherwise the image
      // paints once at the placeholder shape (cover-cropped) and again
      // after the box animates — feels like the thumb zooms in then out.
      final ar = _aspectRatio ?? await _measureAspectFromJpeg(jpeg);
      if (!mounted) return;
      if (ar != null && _aspectRatio == null) {
        widget.videoAspectCache[widget.messageId] = ar;
      }
      setState(() {
        _jpegBytes = jpeg;
        if (ar != null) _aspectRatio = ar;
      });
    } catch (_) {
      // Decode failed (unsupported codec, corrupt bytes, etc.). The bubble
      // stays on its colored placeholder + play overlay — tap still
      // inflates the real player, which renders its own error state.
    }
  }

  Future<double?> _measureAspectFromJpeg(Uint8List jpeg) {
    final completer = Completer<double?>();
    final provider = MemoryImage(jpeg);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        final ar = info.image.width / info.image.height;
        completer.complete(ar > 0 ? ar : null);
      },
      onError: (_, __) {
        stream.removeListener(listener);
        completer.complete(null);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    // Compute the box size from the cached/measured aspect. While unknown,
    // fall back to a 2:1 landscape box — small enough not to dominate the
    // chat scroll, close enough to typical video aspect that the resize
    // jump on most clips is minor.
    var w = widget.width;
    var h = widget.maxHeight / 2;
    final ar = _aspectRatio;
    if (ar != null) {
      h = w / ar;
      if (h > widget.maxHeight) {
        h = widget.maxHeight;
        w = h * ar;
      }
    }

    // Post-tap: hand off to the existing player path. Same Hero tag flows
    // through so the fullscreen MediaOverlay open animation is unchanged.
    if (_expanded) {
      return SizedBox(
        width: w,
        height: h,
        child: TappableMedia(
          videoBytes: widget.videoBytes,
          filename: widget.filename,
          heroTag: widget.heroTag,
          width: w,
          height: h,
          borderRadius: widget.borderRadius,
        ),
      );
    }

    return AnimatedContainer(
      duration: _animDuration,
      curve: Curves.easeOutCubic,
      width: w,
      height: h,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: GestureDetector(
          onTap: () => setState(() => _expanded = true),
          child: Hero(
            tag: widget.heroTag,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_jpegBytes != null)
                  Image.memory(
                    _jpegBytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  )
                else
                  Container(color: tokens.surfaceDeep),
                Container(color: Colors.black.withValues(alpha: 0.18)),
                Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: tokens.starkWhite,
                    size: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
