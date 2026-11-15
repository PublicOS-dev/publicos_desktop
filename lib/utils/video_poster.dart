import 'dart:typed_data';

// DESKTOP DELTA: XFile from cross_file (desktop's picker is file_picker).
import 'package:cross_file/cross_file.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_thumbnail/zero_cached_thumbnail.dart';

import 'package:publicos_desktop/utils/media_dimensions.dart';

/// Video posters.
///
/// A video's poster is frame 0 of the LOCAL clip (the app already holds it):
/// the composer extracts it when the clip is picked and uploads it right
/// after the video lands (`uploadMediaPoster` for `/media/`,
/// `uploadPediaPoster` for `/pedia/`; both served at `<video url>/poster`,
/// the private one sealed per reader). The same frame gives the composer the
/// clip's width and height, which a hero item carries in the signed post,
/// and the poster URL becomes the item's `thumbnail_url`.
///
/// ~960 px on the long side at quality 80: crisp on a full-width tile at 3x,
/// still a few tens of KB (the server caps posters at 1 MB).
class VideoPoster {
  final Uint8List jpeg;
  final int width;
  final int height;

  const VideoPoster({
    required this.jpeg,
    required this.width,
    required this.height,
  });
}

/// Frame 0 of a local clip as a JPEG with its pixel size. Null when the clip
/// could not be decoded; readers then fall back to the old poster flow and
/// the item travels without pixels.
Future<VideoPoster?> videoPosterOf({
  XFile? file,
  Uint8List? bytes,
  required String cacheKey,
}) async {
  try {
    final ThumbnailSource source;
    if (file != null && file.path.isNotEmpty) {
      source = ThumbnailSource.path(file.path, cacheKey: cacheKey);
    } else if (bytes != null) {
      source = ThumbnailSource.bytes(bytes, cacheKey: cacheKey);
    } else {
      return null;
    }
    final jpeg = await ZeroCachedThumbnail.bytes(
      source,
      maxWidth: 960,
      maxHeight: 960,
      quality: 80,
    );
    final size = await imageSizeOf(jpeg);
    if (size == null) return null;
    return VideoPoster(jpeg: jpeg, width: size.$1, height: size.$2);
  } catch (e) {
    Log.w('VideoPoster', 'poster skipped ($cacheKey): $e');
    return null;
  }
}

/// Upload [poster] as the poster of the video at [videoUrl], behind whichever
/// door the URL names. True when the server took it: readers then find it at
/// `PublicOSSsp.posterUrlFor(videoUrl)`. Silent on failure, the author never
/// sees it.
Future<bool> uploadVideoPoster({
  required String videoUrl,
  required VideoPoster poster,
  String? server,
}) async {
  try {
    final uri = Uri.parse(videoUrl);
    final filename = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (filename.isEmpty) return false;
    if (uri.pathSegments.contains('pedia')) {
      return await PublicOSSsp.uploadPediaPoster(filename, poster.jpeg,
          serverAddress: server);
    }
    return await PublicOSSsp.uploadMediaPoster(filename, poster.jpeg,
        serverAddress: server);
  } catch (e) {
    Log.w('VideoPoster', 'poster upload skipped for $videoUrl: $e');
    return false;
  }
}
