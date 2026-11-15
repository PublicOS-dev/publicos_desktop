import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'media_overlay.dart';

/// Backwards-compatibility shim around [MediaOverlay] for the image-only
/// callers. Prefer `MediaOverlay` directly in new code.
///
/// **Client-identical** (publicos_client/lib/widgets/image_overlay.dart).
/// It must stay a shim and not become an image-only viewer of its own: a
/// separate viewer drops MediaOverlay's save button for every profile
/// avatar/banner, NFT card and browser header image.
class ImageOverlay extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageData;
  final String heroTag;
  final VoidCallback onClose;

  const ImageOverlay({
    super.key,
    this.imageUrl,
    this.imageData,
    required this.heroTag,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // MediaOverlay asserts exactly one source; bytes win when both arrive.
    return MediaOverlay(
      imageUrl: imageData == null ? imageUrl : null,
      imageData: imageData,
      heroTag: heroTag,
      onClose: onClose,
    );
  }
}
