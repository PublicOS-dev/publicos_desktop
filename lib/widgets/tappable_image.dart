import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/media_overlay.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// A unified tappable image widget that opens a fullscreen overlay with Hero animation.
/// Use this anywhere you want consistent image viewing behavior.
class TappableImage extends StatelessWidget {
  /// URL for network images
  final String? imageUrl;

  /// Binary data for memory images
  final Uint8List? imageData;

  /// Unique tag for Hero animation - must be unique across the app
  final String heroTag;

  /// Border radius for the image
  final BorderRadius? borderRadius;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// How the image should be inscribed into the box
  final BoxFit fit;

  /// Widget to show while loading (network images only)
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;

  /// Widget to show on error
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// The post's whole media list and this tile's place in it: the overlay
  /// then pages through all of them from here. Null = alone.
  final List<MediaGalleryItem>? gallery;
  final int galleryIndex;

  /// The post's header for the overlay's fixed top row ([MediaOverlay.header]).
  final Widget? overlayHeader;

  const TappableImage({
    super.key,
    this.imageUrl,
    this.imageData,
    required this.heroTag,
    this.borderRadius,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
    this.gallery,
    this.galleryIndex = 0,
    this.overlayHeader,
  }) : assert(
          imageUrl != null || imageData != null,
          'Either imageUrl or imageData must be provided.',
        );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openOverlay(context),
      child: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: _buildImage(context),
        ),
      ),
    );
  }

  void _openOverlay(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            // One lightbox for both, so a lone image gets the header row
            // too.
            gallery != null
                ? MediaOverlay(
                    gallery: gallery,
                    initialIndex: galleryIndex,
                    heroTag: heroTag,
                    header: overlayHeader,
                    onClose: () => Navigator.pop(context),
                  )
                : MediaOverlay(
                    imageUrl: imageUrl,
                    imageData: imageData,
                    heroTag: heroTag,
                    header: overlayHeader,
                    onClose: () => Navigator.pop(context),
                  ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (imageData != null) {
      return Image.memory(
        imageData!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder ??
            (context, error, stackTrace) => _defaultErrorWidget(context),
      );
    }

    // Network images go through ZeroCachedImage for a persistent disk+memory
    // cache. This means pushing a route on top of a feed (compose, channel
    // management, etc.) and popping back doesn't re-fetch/re-decode — the
    // bytes stay cached. `loadingBuilder` is kept on the public API for
    // compatibility: translated to `placeholder`, invoked with a non-null
    // progress event so callers showing a spinner during loading keep
    // working. Progress bytes aren't reported (ZeroCachedImage doesn't
    // stream those), but all existing call sites only distinguish
    // "loading vs done" anyway.
    return ZeroCachedImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: loadingBuilder == null
          ? null
          : (context, _) => loadingBuilder!(
                context,
                const SizedBox.shrink(),
                const ImageChunkEvent(
                  cumulativeBytesLoaded: 0,
                  expectedTotalBytes: null,
                ),
              ),
      errorWidget: (context, _, error) => errorBuilder != null
          ? errorBuilder!(context, error, null)
          : _defaultErrorWidget(context),
    );
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return Container(
      width: width ?? 100,
      height: height ?? 100,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}
