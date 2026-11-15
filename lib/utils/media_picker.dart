import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// **DESKTOP DELTA — same API as the client's `utils/media_picker.dart`,
/// different engine.** The client picks through `image_picker`, whose
/// `pickMedia`/`pickMultipleMedia` (the mixed images+videos flow) have **no
/// Windows implementation** — and its Android-Photo-Picker setup is Android
/// machinery with no meaning here. Desktop swaps the engine for `file_picker`
/// (already a dep; the same choice `media_overlay` made for save-to-gallery)
/// while keeping the public surface byte-compatible: [MediaPickerKind],
/// [PickedMedia], and [pickMedia]'s signature + validation behavior are the
/// client's, so `compose_post_page` ports verbatim.
///
/// The size/MIME validation below (and `_sniffMime`) IS the client's code,
/// unchanged — only the "get files from the OS" step differs.

/// What kinds of media the picker should surface.
enum MediaPickerKind {
  /// Image only — videos won't appear in the picker UI.
  imageOnly,

  /// Mixed images + videos. Caller must guarantee the consumer has a
  /// way to actually send/upload videos (a feed server / SSP) before
  /// using this; otherwise pass [imageOnly] so users don't see options
  /// they can't fulfill.
  imageAndVideo,
}

/// One picked item, with bytes pre-read and MIME pre-resolved.
class PickedMedia {
  final XFile file;
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final bool isVideo;

  const PickedMedia({
    required this.file,
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.isVideo,
  });
}

const List<String> _imageExtensions = [
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif',
];
const List<String> _videoExtensions = [
  'mp4', 'mov', 'webm', 'm4v',
];

/// Pure picker — picks files via the native Windows file dialog, validates
/// size + MIME, returns the bytes ready for the consumer to compress/upload/
/// send.
///
/// - `limit == 1` → single-pick (chat).
/// - `limit > 1` → multi-pick capped at `limit` (compose).
/// - `kind` controls whether videos appear in the picker UI.
/// - `maxMb` is the per-file ceiling; over-cap files are skipped with a
///   snackbar (the rest of the batch is returned).
///
/// Returns an empty list on user-cancel. Does not throw on per-file
/// validation failures — surfaces them as snackbars and continues.
Future<List<PickedMedia>> pickMedia({
  required BuildContext context,
  int limit = 1,
  double maxMb = 100,
  MediaPickerKind kind = MediaPickerKind.imageAndVideo,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: kind == MediaPickerKind.imageOnly
        ? _imageExtensions
        : [..._imageExtensions, ..._videoExtensions],
    allowMultiple: limit > 1,
  );
  if (result == null || result.files.isEmpty) return const [];

  // The dialog has no per-pick cap — enforce client-side, same as the client
  // does for OSes that ignore `limit:`.
  final paths = result.files
      .map((f) => f.path)
      .whereType<String>()
      .take(limit)
      .toList();

  if (!context.mounted) return const [];
  return loadMediaFiles(
      context: context, paths: paths, maxMb: maxMb, kind: kind);
}

/// DESKTOP DELTA: the read + validate half of [pickMedia], split out so files
/// that arrive without the dialog (Explorer files pasted into the chat input,
/// `utils/clipboard_media.dart`) get the same size/MIME gate. Same snackbars,
/// same skip-and-continue behavior.
Future<List<PickedMedia>> loadMediaFiles({
  required BuildContext context,
  required List<String> paths,
  double maxMb = 100,
  MediaPickerKind kind = MediaPickerKind.imageAndVideo,
}) async {
  final maxBytes = (maxMb * 1024 * 1024).round();
  final results = <PickedMedia>[];

  for (final path in paths) {
    final file = XFile(path);
    final Uint8List bytes;
    try {
      bytes = await File(path).readAsBytes();
    } catch (_) {
      continue; // unreadable pick — skip, keep the batch going
    }
    if (!context.mounted) return results;

    if (bytes.length > maxBytes) {
      final sizeMb = (bytes.length / 1024 / 1024).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${file.name}: too large ($sizeMb MB > '
            '${maxMb.toStringAsFixed(0)} MB)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      continue;
    }

    final mime = _sniffMime(bytes, file.name);
    final isVideo = mime.startsWith('video/');
    final isImage = mime.startsWith('image/');

    // The extension filter above narrows the dialog, but a renamed .bin can
    // still walk through it — same belt-and-suspenders drop as the client.
    final allowed =
        kind == MediaPickerKind.imageOnly ? isImage : (isImage || isVideo);
    if (!allowed) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.mediaPickerOnlyImagesVideos),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      continue;
    }

    results.add(PickedMedia(
      file: file,
      bytes: bytes,
      filename: file.name,
      mimeType: mime,
      isVideo: isVideo,
    ));
  }

  return results;
}

/// Best-effort MIME inference. Magic bytes first (jpeg/png/gif/webp/heic/heif/
/// mp4/mov), extension fallback otherwise. Returns `application/octet-stream`
/// for unknowns. Mirrors `PublicOSSsp._sniffMime` so picker decisions match
/// what the server's allow-list will see at upload time.
String _sniffMime(Uint8List bytes, String filename) {
  if (bytes.length >= 12) {
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70) {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));
      if (brand == 'heic' ||
          brand == 'heix' ||
          brand == 'mif1' ||
          brand == 'msf1') {
        return 'image/heic';
      }
      if (brand == 'mp42' || brand == 'isom' || brand == 'qt  ') {
        return 'video/mp4';
      }
    }
  }
  final ext = filename.toLowerCase().split('.').last;
  const extMap = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'heif': 'image/heic',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'm4v': 'video/x-m4v',
  };
  return extMap[ext] ?? 'application/octet-stream';
}
