import 'dart:typed_data';
import 'dart:ui' as ui;

/// Pixel width and height of an encoded image, as Flutter will draw it
/// (EXIF orientation applied, so a phone photo measures the way it shows).
/// Null when the bytes do not decode. A hero item carries these in the
/// signed post so readers lay the card out before the file arrives.
Future<(int width, int height)?> imageSizeOf(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (image.width, image.height);
      image.dispose();
      return size;
    } finally {
      codec.dispose();
    }
  } catch (_) {
    return null;
  }
}
