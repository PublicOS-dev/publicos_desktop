import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'media_picker.dart';

/// Images (and Explorer-copied media files) on the Windows clipboard, for
/// paste-into-the-chat-input. Flutter's `Clipboard` only carries text, so this
/// reads the native clipboard over user32/kernel32/shell32 FFI — no package,
/// same approach as `window_chrome.dart`.
///
/// Formats, in the order they win:
/// 1. **CF_HDROP**: files copied in Explorer. Read from disk and run through
///    [loadMediaFiles], so they get the picker's size/MIME gate.
/// 2. **"PNG"** (registered format): Snipping Tool, browsers, Discord. The
///    bytes already are a PNG file.
/// 3. **CF_DIB**: the bitmap every image copy carries (Paint, older apps).
///    Wrapped in a BMP file header and re-encoded to PNG. CF_DIB rather than
///    CF_DIBV5: a 40-byte header makes the decoder ignore the alpha byte,
///    which Windows often leaves at 0, so a V5 read can come out invisible.
///
/// An image that rides along with text (Word / Excel copies carry a bitmap
/// of the selection) is NOT media: text wins, and the paste stays a text paste.
abstract final class ClipboardMedia {
  static const int _cfDib = 8;
  static const int _cfUnicodeText = 13;
  static const int _cfHdrop = 15;

  static final _user32 = DynamicLibrary.open('user32.dll');
  static final _kernel32 = DynamicLibrary.open('kernel32.dll');
  static final _shell32 = DynamicLibrary.open('shell32.dll');

  static final _openClipboard = _user32.lookupFunction<Int32 Function(IntPtr),
      int Function(int)>('OpenClipboard');
  static final _closeClipboard = _user32
      .lookupFunction<Int32 Function(), int Function()>('CloseClipboard');
  static final _isFormatAvailable = _user32.lookupFunction<
      Int32 Function(Uint32), int Function(int)>('IsClipboardFormatAvailable');
  static final _getClipboardData = _user32.lookupFunction<
      IntPtr Function(Uint32), int Function(int)>('GetClipboardData');
  static final _registerFormat = _user32.lookupFunction<
      Uint32 Function(Pointer<Utf16>),
      int Function(Pointer<Utf16>)>('RegisterClipboardFormatW');
  static final _globalLock = _kernel32.lookupFunction<
      Pointer<Uint8> Function(IntPtr), Pointer<Uint8> Function(int)>('GlobalLock');
  static final _globalUnlock = _kernel32.lookupFunction<Int32 Function(IntPtr),
      int Function(int)>('GlobalUnlock');
  static final _globalSize = _kernel32.lookupFunction<IntPtr Function(IntPtr),
      int Function(int)>('GlobalSize');
  static final _dragQueryFile = _shell32.lookupFunction<
      Uint32 Function(IntPtr, Uint32, Pointer<Utf16>, Uint32),
      int Function(int, int, Pointer<Utf16>, int)>('DragQueryFileW');

  static final int _cfPng = using((arena) =>
      _registerFormat('PNG'.toNativeUtf16(allocator: arena)));

  static bool _has(int format) => _isFormatAvailable(format) != 0;

  /// Synchronous, no clipboard lock taken — cheap enough for a key handler.
  /// True when a paste should become an attachment instead of text.
  static bool hasMedia() {
    if (_has(_cfHdrop)) return true;
    if (_has(_cfUnicodeText)) return false;
    return _has(_cfPng) || _has(_cfDib);
  }

  /// Reads what [hasMedia] promised. Empty when the clipboard changed under
  /// us, could not be opened, or held only files that fail the media gate.
  static Future<List<PickedMedia>> read({
    required BuildContext context,
    required MediaPickerKind kind,
    required int limit,
  }) async {
    final grab = await _grab();
    if (grab == null) return const [];
    if (grab.paths != null) {
      if (!context.mounted) return const [];
      return loadMediaFiles(
          context: context, paths: grab.paths!.take(limit).toList(), kind: kind);
    }
    final png = grab.png ?? await _dibToPng(grab.dib!);
    if (png == null) return const [];
    return [
      PickedMedia(
        file: XFile.fromData(png, name: 'clipboard.png', mimeType: 'image/png'),
        bytes: png,
        filename: 'clipboard.png',
        mimeType: 'image/png',
        isVideo: false,
      ),
    ];
  }

  /// Copies the winning format out while the clipboard is open, then closes
  /// it at once. OpenClipboard fails while another app holds the clipboard
  /// (clipboard managers do, briefly), hence the short retry.
  static Future<_Grab?> _grab() async {
    var opened = false;
    for (var i = 0; i < 5 && !opened; i++) {
      opened = _openClipboard(0) != 0;
      if (!opened) await Future.delayed(const Duration(milliseconds: 20));
    }
    if (!opened) return null;
    try {
      if (_has(_cfHdrop)) {
        final hDrop = _getClipboardData(_cfHdrop);
        return hDrop == 0 ? null : _Grab(paths: _dropPaths(hDrop));
      }
      if (_has(_cfPng)) {
        final bytes = _globalBytes(_getClipboardData(_cfPng));
        if (bytes != null) return _Grab(png: bytes);
      }
      if (_has(_cfDib)) {
        final bytes = _globalBytes(_getClipboardData(_cfDib));
        if (bytes != null) return _Grab(dib: bytes);
      }
      return null;
    } finally {
      _closeClipboard();
    }
  }

  static Uint8List? _globalBytes(int handle) {
    if (handle == 0) return null;
    final ptr = _globalLock(handle);
    if (ptr == nullptr) return null;
    try {
      return Uint8List.fromList(ptr.asTypedList(_globalSize(handle)));
    } finally {
      _globalUnlock(handle);
    }
  }

  static List<String> _dropPaths(int hDrop) {
    final count = _dragQueryFile(hDrop, 0xFFFFFFFF, nullptr, 0);
    final paths = <String>[];
    for (var i = 0; i < count; i++) {
      final len = _dragQueryFile(hDrop, i, nullptr, 0);
      final buf = calloc<Uint16>(len + 1).cast<Utf16>();
      try {
        _dragQueryFile(hDrop, i, buf, len + 1);
        paths.add(buf.toDartString());
      } finally {
        calloc.free(buf);
      }
    }
    return paths;
  }

  /// CF_DIB is a BMP file minus its 14-byte file header: prepend one, decode,
  /// re-encode as PNG. Off the UI isolate — a 4K screenshot takes a while.
  static Future<Uint8List?> _dibToPng(Uint8List dib) => Isolate.run(() {
        if (dib.length < 40) return null;
        final info = ByteData.sublistView(dib);
        final headerSize = info.getUint32(0, Endian.little);
        final bitCount = info.getUint16(14, Endian.little);
        final compression = info.getUint32(16, Endian.little);
        final colorsUsed = info.getUint32(32, Endian.little);
        // BI_BITFIELDS on a 40-byte header: three DWORD masks follow it.
        final masks = (headerSize == 40 && compression == 3) ? 12 : 0;
        final paletteEntries = colorsUsed != 0
            ? colorsUsed
            : (bitCount <= 8 ? 1 << bitCount : 0);
        final pixelOffset = 14 + headerSize + masks + paletteEntries * 4;

        final bmp = Uint8List(14 + dib.length);
        ByteData.sublistView(bmp)
          ..setUint8(0, 0x42) // 'B'
          ..setUint8(1, 0x4D) // 'M'
          ..setUint32(2, bmp.length, Endian.little)
          ..setUint32(10, pixelOffset, Endian.little);
        bmp.setRange(14, bmp.length, dib);

        final image = img.decodeBmp(bmp);
        return image == null ? null : img.encodePng(image);
      });
}

class _Grab {
  final List<String>? paths;
  final Uint8List? png;
  final Uint8List? dib;
  const _Grab({this.paths, this.png, this.dib});
}
