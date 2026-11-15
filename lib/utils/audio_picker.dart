import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// One picked audio file, bytes read and MIME resolved. The post composer's
/// Audio button (PublicOS Feed v1 `audio`: the post's one sound track).
class PickedAudio {
  final Uint8List bytes;
  final String filename;
  final String mimeType;

  const PickedAudio({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

/// The four audio types every SSP allow-lists (the server's `allowed_types`:
/// `audio/mpeg`, `audio/mp4`, `audio/wav`, `audio/ogg`). The picker offers
/// only these extensions, and the upload names the type explicitly (Core's
/// sniffer and the server's both fall short on headerless audio).
const Map<String, String> audioMimeByExtension = {
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'oga': 'audio/ogg',
};

/// Pick one audio file via the system file picker: size-gated before the
/// bytes are read, bytes read path-first (in-memory on web). Null on cancel
/// or on a rejected pick (a snackbar says why).
Future<PickedAudio?> pickAudio({
  required BuildContext context,
  double maxMb = 100,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: audioMimeByExtension.keys.toList(),
    withData: false,
  );
  if (!context.mounted || result == null || result.files.isEmpty) return null;

  final picked = result.files.first;
  final filename = picked.name;
  final ext = filename.contains('.') ? filename.toLowerCase().split('.').last : '';
  final mime = audioMimeByExtension[ext];
  if (mime == null) {
    _toast(context, context.l10n.composePostPageAudioUnsupported);
    return null;
  }

  final maxBytes = (maxMb * 1024 * 1024).round();
  if (picked.size > maxBytes) {
    final sizeMb = (picked.size / 1024 / 1024).toStringAsFixed(1);
    _toast(
      context,
      context.l10n.documentPickerTooLarge(sizeMb, maxMb.toStringAsFixed(0)),
    );
    return null;
  }

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
  return PickedAudio(bytes: bytes, filename: filename, mimeType: mime);
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
