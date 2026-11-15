import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Result of an inline-compress pass — bytes are smaller-than-or-equal to
/// the input, and `mimeType` may have shifted (e.g. heic → jpeg if the
/// underlying compressor downconverts).
class CompressedImage {
  final Uint8List bytes;
  final String mimeType;

  const CompressedImage({required this.bytes, required this.mimeType});
}

/// DELTA(desktop): the client's `ImageUtils` runs on `flutter_image_compress`,
/// which has NO Windows implementation (federated impls: android/ios, macos,
/// web, ohos — same trap class as `gal` and `image_picker`). This is the
/// Windows twin — SAME class name, SAME `compressForInline` contract and
/// downscale-first step table, engine swapped to the pure-Dart `image`
/// package, run through `compute()` so a multi-megapixel decode doesn't jank
/// the UI isolate. WebP encoding doesn't exist in pure Dart (`image` decodes
/// webp but doesn't encode it), so webp inputs downconvert to jpeg — the
/// consumer already handles MIME shifts (that's the heic→jpeg path on mobile).
class ImageUtils {
  // Max size for inline (LOW) attachments inside the XMTP envelope.
  static const int MAX_SIZE_BYTES = 1024 * 1024;

  /// Compress image bytes for the inline-LOW path. Pure: no picker, no
  /// dialogs, no UI side-effects. Image-only — videos go through the HD
  /// path where compression doesn't apply.
  ///
  /// Returns the input untouched if already under the inline ceiling, or a
  /// progressively-quality-reduced (then resolution-reduced if still too
  /// big) version that fits.
  static Future<CompressedImage> compressForInline(
    Uint8List input,
    String mimeType,
    String filename,
  ) async {
    if (input.length <= MAX_SIZE_BYTES) {
      return CompressedImage(bytes: input, mimeType: mimeType);
    }

    final usePng = _isPng(mimeType, filename);
    return compute(
      _compressInIsolate,
      _CompressJob(input: input, usePng: usePng),
    );
  }

  static bool _isPng(String mimeType, String filename) {
    if (mimeType.toLowerCase() == 'image/png') return true;
    return filename.toLowerCase().split('.').last == 'png';
  }
}

class _CompressJob {
  final Uint8List input;
  final bool usePng;
  const _CompressJob({required this.input, required this.usePng});
}

CompressedImage _compressInIsolate(_CompressJob job) {
  final decoded = img.decodeImage(job.input);
  if (decoded == null) {
    // Undecodable → hand the original back; the caller's size check routes it
    // to the HD/too-large path exactly as a failed compress would on mobile.
    return CompressedImage(bytes: job.input, mimeType: 'image/jpeg');
  }

  // Downscale-FIRST — same step table as the client: resolution, not quality,
  // dominates file size, so one downscale+quality pass gets almost any photo
  // under the inline ceiling. Each step is [quality, min-side]; scaling keeps
  // aspect ratio with the SHORTER side ≈ min-side (the compressWithList
  // contract this twin mirrors).
  const steps = [
    [88, 1280],
    [68, 1024],
    [48, 800],
  ];

  Uint8List result = job.input;
  String outMime = job.usePng ? 'image/png' : 'image/jpeg';
  for (final s in steps) {
    final quality = s[0];
    final minSide = s[1];

    img.Image frame = decoded;
    final shorter =
        decoded.width < decoded.height ? decoded.width : decoded.height;
    if (shorter > minSide) {
      final scale = minSide / shorter;
      frame = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
        interpolation: img.Interpolation.linear,
      );
    }

    if (job.usePng) {
      result = Uint8List.fromList(img.encodePng(frame));
      // PNG has no quality knob; if a downscaled PNG still doesn't fit, the
      // next step's smaller min-side is the only lever — same shape as the
      // client's loop, where PNG steps also only shrink by resolution.
    } else {
      result = Uint8List.fromList(img.encodeJpg(frame, quality: quality));
      outMime = 'image/jpeg';
    }
    if (result.length <= ImageUtils.MAX_SIZE_BYTES) break;
  }

  return CompressedImage(bytes: result, mimeType: outMime);
}
