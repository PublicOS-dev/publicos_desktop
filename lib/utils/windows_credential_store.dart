import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/// Small values kept in Windows Credential Manager (Control Panel >
/// Credential Manager > Windows Credentials), under `PublicOS/<key>`.
///
/// Why not `flutter_secure_storage`: on Windows it keeps only its AES key in
/// Credential Manager and writes each value as an encrypted `<key>.secure`
/// file in the app's own data folder. The app PIN must not sit in our folder
/// so its three values go straight to the OS store.
/// Direct advapi32 FFI, no package, for three calls.
abstract final class WindowsCredentialStore {
  static const int _credTypeGeneric = 1;
  static const int _credPersistLocalMachine = 2;
  static const String _prefix = 'PublicOS/';

  static final DynamicLibrary _advapi = DynamicLibrary.open('advapi32.dll');

  static final _credWrite = _advapi.lookupFunction<
      Int32 Function(Pointer<_Credential>, Uint32),
      int Function(Pointer<_Credential>, int)>('CredWriteW');

  static final _credRead = _advapi.lookupFunction<
      Int32 Function(
          Pointer<Utf16>, Uint32, Uint32, Pointer<Pointer<_Credential>>),
      int Function(Pointer<Utf16>, int, int,
          Pointer<Pointer<_Credential>>)>('CredReadW');

  static final _credDelete = _advapi.lookupFunction<
      Int32 Function(Pointer<Utf16>, Uint32, Uint32),
      int Function(Pointer<Utf16>, int, int)>('CredDeleteW');

  static final _credFree = _advapi.lookupFunction<
      Void Function(Pointer<Void>), void Function(Pointer<Void>)>('CredFree');

  static Future<String?> read(String key) async {
    if (!Platform.isWindows) return null;
    final target = '$_prefix$key'.toNativeUtf16();
    final out = calloc<Pointer<_Credential>>();
    try {
      if (_credRead(target, _credTypeGeneric, 0, out) == 0) return null;
      final cred = out.value.ref;
      final bytes = Uint8List.fromList(
          cred.credentialBlob.asTypedList(cred.credentialBlobSize));
      _credFree(out.value.cast());
      return utf8.decode(bytes);
    } finally {
      calloc.free(target);
      calloc.free(out);
    }
  }

  static Future<void> write(String key, String value) async {
    if (!Platform.isWindows) return;
    final target = '$_prefix$key'.toNativeUtf16();
    final user = 'PublicOS'.toNativeUtf16();
    final bytes = utf8.encode(value);
    final blob = calloc<Uint8>(bytes.length);
    blob.asTypedList(bytes.length).setAll(0, bytes);
    final cred = calloc<_Credential>();
    try {
      cred.ref
        ..type = _credTypeGeneric
        ..targetName = target
        ..credentialBlobSize = bytes.length
        ..credentialBlob = blob
        ..persist = _credPersistLocalMachine
        ..userName = user;
      if (_credWrite(cred, 0) == 0) {
        throw Exception('Credential Manager refused to store $key');
      }
    } finally {
      calloc.free(cred);
      calloc.free(blob);
      calloc.free(user);
      calloc.free(target);
    }
  }

  static Future<void> delete(String key) async {
    if (!Platform.isWindows) return;
    final target = '$_prefix$key'.toNativeUtf16();
    try {
      _credDelete(target, _credTypeGeneric, 0);
    } finally {
      calloc.free(target);
    }
  }
}

/// Win32 `CREDENTIALW`.
final class _Credential extends Struct {
  @Uint32()
  external int flags;
  @Uint32()
  external int type;
  external Pointer<Utf16> targetName;
  external Pointer<Utf16> comment;
  @Uint32()
  external int lastWrittenLow;
  @Uint32()
  external int lastWrittenHigh;
  @Uint32()
  external int credentialBlobSize;
  external Pointer<Uint8> credentialBlob;
  @Uint32()
  external int persist;
  @Uint32()
  external int attributeCount;
  external Pointer<Void> attributes;
  external Pointer<Utf16> targetAlias;
  external Pointer<Utf16> userName;
}
