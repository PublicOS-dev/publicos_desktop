import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_desktop/utils/app_update.dart';
import 'package:web3dart/web3dart.dart';

// A throwaway key: it signs the test certificates and stands in for a session
// key of the release account.
final _releaseKey = EthPrivateKey.fromHex(
    '0x4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318');
final _strangerKey = EthPrivateKey.fromHex(
    '0x8da4ef21b864d2cc526dbdb2a120bd2874c36c9d0a1fb7f8c63d7f7a8b41de8f');

const _ownBuild = 202611150000;

Map<String, dynamic> _fields({
  String app = 'publicos_desktop',
  int build = 202611151800,
  int chainId = 4489,
  String platform = 'win-x64',
  String zipName = 'publicos_desktop_win-x64.zip',
  String zipSha256 =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
}) =>
    {
      'app': app,
      'build': build,
      'chain_id': chainId,
      'platform': platform,
      'signed_at': '2026-11-15T18:00:00Z',
      'version': '1.0.0',
      'zip_name': zipName,
      'zip_sha256': zipSha256,
      'zip_size': 55310368,
    };

String _certificate(Map<String, dynamic> fields, {EthPrivateKey? key}) {
  final signedObject = jsonEncode(fields);
  final sig = (key ?? _releaseKey).signPersonalMessageToUint8List(
      Uint8List.fromList(utf8.encode(signedObject)));
  return jsonEncode({
    'signed_object': signedObject,
    'signature': bytesToHex(sig, include0x: true),
  });
}

Future<bool> _isReleaseKey(String signer) async =>
    signer.toLowerCase() == _releaseKey.address.eip55With0x.toLowerCase();

Future<UpdateVerdict> _verify(String certificate) =>
    AppUpdate.verifyCertificate(certificate,
        ownBuild: _ownBuild, isReleaseKey: _isReleaseKey);

void main() {
  test('a newer build signed by a release key is offered', () async {
    final v = await _verify(_certificate(_fields()));
    expect(v.refusal, isNull);
    expect(v.offer!.build, 202611151800);
    expect(v.offer!.zipName, 'publicos_desktop_win-x64.zip');
    expect(v.offer!.signer.toLowerCase(),
        _releaseKey.address.eip55With0x.toLowerCase());
  });

  test('a signer that is not a release key is refused', () async {
    final v = await _verify(_certificate(_fields(), key: _strangerKey));
    expect(v.offer, isNull);
    expect(v.refusal, contains('not a session key'));
  });

  test('a certificate changed after signing is refused', () async {
    final good = jsonDecode(_certificate(_fields())) as Map<String, dynamic>;
    good['signed_object'] = (good['signed_object'] as String)
        .replaceFirst('aaaaaaaa', 'bbbbbbbb');
    final v = await _verify(jsonEncode(good));
    expect(v.offer, isNull);
  });

  test('the same build and an older build are refused', () async {
    final same = await _verify(_certificate(_fields(build: _ownBuild)));
    expect(same.refusal, contains('not newer'));
    final older = await _verify(_certificate(_fields(build: 202611010000)));
    expect(older.refusal, contains('not newer'));
  });

  test('another chain, app or platform is refused', () async {
    expect((await _verify(_certificate(_fields(chainId: 44890)))).refusal,
        contains('another chain'));
    expect((await _verify(_certificate(_fields(app: 'marcha')))).refusal,
        contains('another app'));
    expect((await _verify(_certificate(_fields(platform: 'macos')))).refusal,
        contains('another platform'));
  });

  test('a zip name that is not a plain file name is refused', () async {
    for (final name in [
      '../evil.zip',
      'https://evil.example/a.zip',
      'a/b.zip',
      'app.exe',
    ]) {
      final v = await _verify(_certificate(_fields(zipName: name)));
      expect(v.offer, isNull, reason: name);
    }
  });

  test('a malformed hash is refused', () async {
    final v = await _verify(_certificate(_fields(zipSha256: 'abc')));
    expect(v.refusal, contains('malformed'));
  });

  test('no answer from the chain means no offer', () async {
    final v = await AppUpdate.verifyCertificate(
      _certificate(_fields()),
      ownBuild: _ownBuild,
      isReleaseKey: (_) async => throw 'rpc unreachable',
    );
    expect(v.offer, isNull);
    expect(v.refusal, contains('chain check failed'));
  });

  test('garbage is refused', () async {
    expect((await _verify('not json')).offer, isNull);
    expect((await _verify('[]')).offer, isNull);
    expect((await _verify('{"signed_object":"{}","signature":"0x00"}')).offer,
        isNull);
  });

  test('the hand-over script copies, never mirrors', () {
    final script = AppUpdate.helperScript(
      pid: 4242,
      build: 202611151800,
      source: r'C:\u\update\staged\app',
      appDir: r'C:\apps\PublicOS',
      staged: r'C:\u\update\staged',
      database: r'C:\u\publicos.sqlite',
      log: r'C:\u\update\update.log',
    );
    expect(script, contains('PID eq 4242'));
    expect(script, contains(r'robocopy "C:\u\update\staged\app" "C:\apps\PublicOS" /E'));
    expect(script, isNot(contains('/MIR')));
    expect(script, contains('publicos.sqlite.before-update'));
  });

  test('the hand-over script stops waiting and ends the old app', () {
    final script = AppUpdate.helperScript(
      pid: 4242,
      build: 202611151800,
      source: r'C:\u\update\staged\app',
      appDir: r'C:\apps\PublicOS',
      staged: r'C:\u\update\staged',
      database: r'C:\u\publicos.sqlite',
      log: r'C:\u\update\update.log',
    );
    expect(script, contains('if %WAITED% GEQ ${AppUpdate.waitSeconds}'));
    expect(script, contains('taskkill /F /PID 4242'));
    // The copy comes after the wait ends, on either way out of it.
    expect(script.indexOf(':gone'), lessThan(script.indexOf('robocopy')));
  });

  test('the hidden start runs a script, in a folder with a space', () async {
    if (!Platform.isWindows) return;
    final dir = Directory.systemTemp.createTempSync('upd test ');
    final marker = File('${dir.path}\\ran.txt');
    final script = File('${dir.path}\\probe.cmd')
      ..writeAsStringSync('@echo off\r\ntasklist >nul\r\necho ok > "${marker.path}"\r\n');
    await AppUpdate.launchHidden(script.path);
    for (var i = 0; i < 40 && !marker.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    expect(marker.existsSync(), isTrue);
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });
}
