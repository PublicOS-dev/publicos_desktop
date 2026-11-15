import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hand-rolled "open with" — no third-party plugin. Writes [bytes] to a temp
/// file under the app cache and asks the OS to hand it to the user's chosen
/// app.
///
/// DELTA(desktop): the client's implementation drives a
/// `com.publicos/openfile` MethodChannel whose native handlers live in
/// MainActivity.kt / AppDelegate.swift — neither exists on Windows, so the
/// channel call would throw MissingPluginException and every open would
/// silently return false. Same contract, Windows engine: `launchUrl` on a
/// `file://` URI (ShellExecute → the user's default app for that extension).
/// Returns true if the OS presented an opener, false on any failure.
Future<bool> openFileWithSystem({
  required Uint8List bytes,
  required String filename,
  String? mimeType,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    // Strip path separators / illegal chars so the cached name is a safe leaf.
    final safe = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/shared_docs/$safe');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    return await launchUrl(Uri.file(file.path));
  } catch (_) {
    return false;
  }
}
