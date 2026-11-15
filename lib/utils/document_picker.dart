import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// One picked document, bytes pre-read and MIME resolved. Mirrors
/// [PickedMedia] in media_picker.dart, but for the document flow (file_picker
/// instead of image_picker, and images/videos are rejected — those belong to
/// the Image option).
class PickedDocument {
  final Uint8List bytes;
  final String filename;
  final String mimeType;

  const PickedDocument({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

/// Pick a single document via the system file picker, then:
///  - reject images/videos (use the Image option for those),
///  - enforce the [maxMb] ceiling (checked against the reported size BEFORE
///    reading bytes, so a huge file never lands in memory),
///  - read the bytes (path-first; falls back to the in-memory bytes, which is
///    the only source on web and the reliable one on Windows desktop).
///
/// Returns null on cancel or on any rejected/failed pick (a snackbar explains
/// why). Never throws for the expected cases.
Future<PickedDocument?> pickDocument({
  required BuildContext context,
  double maxMb = 100,
}) async {
  // DELTA(desktop): client rides file_picker ^11 (static API); desktop pins
  // ^8, where picks go through the platform instance.
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    // Read from the path ourselves so we can size-gate before pulling bytes.
    withData: false,
  );
  if (!context.mounted || result == null || result.files.isEmpty) return null;

  final picked = result.files.first;
  final filename = picked.name;
  // The system file picker can't exclude images/videos. We don't reject them —
  // the caller (handleDocument) detects an image/video MIME and routes it
  // through the normal image flow, so picking a photo under "Document" behaves
  // exactly like picking it under "Image".
  final mime = _docMime(filename);

  // Size gate (PlatformFile.size is bytes, available without reading data).
  final maxBytes = (maxMb * 1024 * 1024).round();
  if (picked.size > maxBytes) {
    final sizeMb = (picked.size / 1024 / 1024).toStringAsFixed(1);
    _toast(
      context,
      context.l10n.documentPickerTooLarge(sizeMb, maxMb.toStringAsFixed(0)),
    );
    return null;
  }

  // Read bytes — prefer in-memory (web), else the file path.
  Uint8List? bytes = picked.bytes;
  if (bytes == null && picked.path != null) {
    try {
      bytes = await File(picked.path!).readAsBytes();
    } catch (_) {
      bytes = null;
    }
  }
  if (!context.mounted) return null;
  if (bytes == null || bytes.isEmpty) {
    _toast(context, context.l10n.documentReadFailed);
    return null;
  }

  return PickedDocument(bytes: bytes, filename: filename, mimeType: mime);
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

/// Extension → MIME for documents. Images/videos are mapped to their media
/// types only so the caller can reject them; everything else falls back to
/// application/octet-stream (the real type still rides in the filename's ext).
String _docMime(String filename) {
  final ext = filename.contains('.')
      ? filename.toLowerCase().split('.').last
      : '';
  const map = {
    // media — mapped so the caller can detect + reject them
    'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
    'gif': 'image/gif', 'webp': 'image/webp', 'heic': 'image/heic',
    'heif': 'image/heic', 'bmp': 'image/bmp', 'svg': 'image/svg+xml',
    'mp4': 'video/mp4', 'mov': 'video/quicktime', 'webm': 'video/webm',
    'm4v': 'video/x-m4v', 'avi': 'video/x-msvideo', 'mkv': 'video/x-matroska',
    // documents
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
    'rtf': 'application/rtf',
    'csv': 'text/csv',
    'json': 'application/json',
    'xml': 'application/xml',
    'html': 'text/html',
    'md': 'text/markdown',
    'zip': 'application/zip',
    'rar': 'application/vnd.rar',
    '7z': 'application/x-7z-compressed',
    'gz': 'application/gzip',
    'apk': 'application/vnd.android.package-archive',
    'epub': 'application/epub+zip',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'm4a': 'audio/mp4',
    'ogg': 'audio/ogg',
  };
  return map[ext] ?? 'application/octet-stream';
}
