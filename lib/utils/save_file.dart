import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// DELTA(desktop): the client hands exported files (DB backups, chat
/// exports, debug logs) to the OS share sheet via share_plus — Windows has
/// no share sheet, so the desktop counterpart is a native save dialog (the
/// media_overlay convention: the dialog IS the permission grant, and cancel
/// is not an error). Copies [sourcePath] to the user's chosen location.
/// Returns the saved path, or null on cancel.
Future<String?> saveFileWithDialog({
  required String sourcePath,
  String? suggestedName,
}) async {
  final target = await FilePicker.platform.saveFile(
    fileName:
        suggestedName ?? sourcePath.split(Platform.pathSeparator).last,
  );
  if (target == null) return null;
  await File(sourcePath).copy(target);
  return target;
}

/// Save in-memory [bytes] (a chat document) through the native save dialog.
/// Returns the saved path, or null on cancel; throws on a write failure.
/// Client twin: publicos_client utils/save_file.dart (there file_picker writes
/// the bytes itself; on Windows it only returns the path, so we write here).
Future<String?> saveBytesWithDialog({
  required Uint8List bytes,
  required String filename,
}) async {
  final safe = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final target = await FilePicker.platform.saveFile(fileName: safe);
  if (target == null) return null;
  await File(target).writeAsBytes(bytes, flush: true);
  return target;
}
