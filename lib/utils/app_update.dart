import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hash;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:web3dart/web3dart.dart';

/// The app updates itself, and decides whether a build is genuine by asking
/// the chain.
///
/// A release is a zip plus a small certificate: a JSON string naming the build
/// and the zip's hash, signed (EIP-191) by a session key of the release
/// account. The app recovers the signer, asks the public node whether that key
/// is a session key of [releaseAccount], and only then offers the build. The
/// download host stores the files and decides nothing.
///
/// Any "no" along the way means no offer and one log line; the app runs as it
/// is.

/// A build the chain vouched for and that is newer than this one.
class UpdateOffer {
  final int build;
  final String version;
  final String zipName;
  final String zipSha256;
  final int zipSize;
  final String signer;

  const UpdateOffer({
    required this.build,
    required this.version,
    required this.zipName,
    required this.zipSha256,
    required this.zipSize,
    required this.signer,
  });
}

/// The answer of [AppUpdate.verifyCertificate]: an offer, or why there is none.
class UpdateVerdict {
  final UpdateOffer? offer;
  final String? refusal;
  const UpdateVerdict.offer(UpdateOffer this.offer) : refusal = null;
  const UpdateVerdict.refused(String this.refusal) : offer = null;
}

class AppUpdate {
  AppUpdate._();

  static const _tag = '[UPDATE]';

  /// This build's id, a UTC `yyyymmddHHMM` number set by the packaging script.
  /// 0 in a debug or hand-made build: the updater is off there.
  static const int ownBuild = int.fromEnvironment('PUBLICOS_BUILD');

  /// Where releases are downloaded from. The certificate names a file, never an
  /// address, so a certificate cannot send the app anywhere else.
  static const String downloadBase = String.fromEnvironment(
    'PUBLICOS_UPDATE_BASE',
    defaultValue:
        'https://github.com/PublicOS-dev/publicos_desktop/releases/latest/download/',
  );

  /// The page offered when this PC cannot update in place.
  static const String downloadPage =
      'https://github.com/PublicOS-dev/publicos_desktop/releases/latest';

  static const String certificateName = 'publicos_desktop_win-x64.json';
  static const String appName = 'publicos_desktop';
  static const String platform = 'win-x64';
  static const String exeName = 'publicos_desktop.exe';

  /// The account whose session keys sign releases (jmsl).
  static const String releaseAccount =
      '0xcdac50Be80cAB95Ab6C989CF80f69D1C5F04d039';

  /// The current offer, or null. The status bar listens to it.
  static final ValueNotifier<UpdateOffer?> offer = ValueNotifier(null);

  static Timer? _timer;

  /// Checks now and every six hours while the app runs. Never throws.
  static void start() {
    if (ownBuild == 0 || !Platform.isWindows || _timer != null) return;
    unawaited(check());
    _timer = Timer.periodic(const Duration(hours: 6), (_) => check());
  }

  /// Fetches the latest certificate and sets [offer] when it holds.
  static Future<void> check() async {
    if (ownBuild == 0) return;
    try {
      final res = await http
          .get(Uri.parse('$downloadBase$certificateName'))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        debugPrint('$_tag no certificate (HTTP ${res.statusCode})');
        return;
      }
      final verdict = await verifyCertificate(
        utf8.decode(res.bodyBytes),
        ownBuild: ownBuild,
        isReleaseKey: isReleaseKeyOnChain,
      );
      if (verdict.offer == null) {
        debugPrint('$_tag no offer: ${verdict.refusal}');
        return;
      }
      debugPrint('$_tag build ${verdict.offer!.build} is on offer');
      offer.value = verdict.offer;
    } catch (e) {
      debugPrint('$_tag check failed: $e');
    }
  }

  /// Every check that needs no download. [isReleaseKey] answers whether an
  /// address is a session key of the release account.
  static Future<UpdateVerdict> verifyCertificate(
    String certificateText, {
    required int ownBuild,
    required Future<bool> Function(String signer) isReleaseKey,
  }) async {
    final Map<String, dynamic> so;
    final String signedObject;
    final String signature;
    try {
      final cert = jsonDecode(certificateText);
      if (cert is! Map<String, dynamic>) {
        return const UpdateVerdict.refused('certificate is not an object');
      }
      final rawObject = cert['signed_object'];
      final rawSignature = cert['signature'];
      if (rawObject is! String || rawSignature is! String) {
        return const UpdateVerdict.refused('certificate lacks its two fields');
      }
      signedObject = rawObject;
      signature = rawSignature;
      final decoded = jsonDecode(signedObject);
      if (decoded is! Map<String, dynamic>) {
        return const UpdateVerdict.refused('signed object is not an object');
      }
      so = decoded;
    } catch (e) {
      return UpdateVerdict.refused('certificate does not parse: $e');
    }

    if (so['app'] != appName) {
      return const UpdateVerdict.refused('certificate is for another app');
    }
    if (so['platform'] != platform) {
      return const UpdateVerdict.refused('certificate is for another platform');
    }
    if (so['chain_id'] != PublicOS.CHAIN_ID) {
      return const UpdateVerdict.refused('certificate is for another chain');
    }
    final build = so['build'];
    final version = so['version'];
    final zipName = so['zip_name'];
    final zipSha256 = so['zip_sha256'];
    final zipSize = so['zip_size'];
    if (build is! int ||
        version is! String ||
        zipName is! String ||
        zipSha256 is! String ||
        zipSize is! int) {
      return const UpdateVerdict.refused('certificate fields have wrong types');
    }
    if (build <= ownBuild) {
      return UpdateVerdict.refused('build $build is not newer than $ownBuild');
    }
    if (!RegExp(r'^[A-Za-z0-9._-]+\.zip$').hasMatch(zipName) ||
        zipName.contains('..')) {
      return const UpdateVerdict.refused('zip name is not a plain file name');
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(zipSha256) || zipSize <= 0) {
      return const UpdateVerdict.refused('zip hash or size is malformed');
    }

    final signer = PublicOSSsp.recoverEip191Signer(signedObject, signature);
    if (signer == null) {
      return const UpdateVerdict.refused('signature does not recover');
    }
    final bool vouched;
    try {
      vouched = await isReleaseKey(signer);
    } catch (e) {
      return UpdateVerdict.refused('chain check failed: $e');
    }
    if (!vouched) {
      return UpdateVerdict.refused(
          '$signer is not a session key of the release account');
    }

    return UpdateVerdict.offer(UpdateOffer(
      build: build,
      version: version,
      zipName: zipName,
      zipSha256: zipSha256,
      zipSize: zipSize,
      signer: signer,
    ));
  }

  /// The chain check, through the public node only: the app's own node may be
  /// one the user picked, and the answer must not depend on that choice.
  static Future<bool> isReleaseKeyOnChain(String signer) async {
    final httpClient = http.Client();
    final client = Web3Client(PublicOS.PUBLIC_RPC_URL, httpClient);
    try {
      final registry = ModuleRegistry(
        address: PublicOSBsp.moduleRegistryAddress,
        client: client,
      );
      final accountManager = await registry.getModuleAddress((
        moduleType: keccak256(Uint8List.fromList(utf8.encode('ACCOUNT_MANAGER'))),
      )).timeout(const Duration(seconds: 20));
      return await AccountManager(address: accountManager, client: client)
          .isValidSessionForAccount((
        accountAddress: EthereumAddress.fromHex(releaseAccount),
        sessionAddress: EthereumAddress.fromHex(signer),
      )).timeout(const Duration(seconds: 20));
    } finally {
      await client.dispose();
      httpClient.close();
    }
  }

  /// False when the app sits somewhere it cannot write (Program Files, a
  /// read-only share), or under a path the hand-over script cannot carry.
  static bool canUpdateInPlace() {
    final dir = _appDir();
    if (RegExp(r'[%"^&!]').hasMatch(dir)) return false;
    try {
      final probe = File('$dir\\.update_probe');
      probe.writeAsStringSync('');
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Downloads the offered zip, checks its size and hash against the
  /// certificate, unpacks it and returns the folder that holds the new exe.
  /// Throws with a plain reason on any failure; nothing of the app is touched.
  static Future<String> download(
    UpdateOffer offer, {
    void Function(double fraction)? onProgress,
  }) async {
    final dir = await _updateDir();
    final zip = File('${dir.path}\\${offer.zipName}');
    final staged = Directory('${dir.path}\\staged');
    if (staged.existsSync()) staged.deleteSync(recursive: true);
    if (zip.existsSync()) zip.deleteSync();

    final client = http.Client();
    try {
      final res = await client
          .send(http.Request('GET', Uri.parse('$downloadBase${offer.zipName}')));
      if (res.statusCode != 200) {
        throw 'download answered HTTP ${res.statusCode}';
      }
      final digestSink = _DigestSink();
      final hasher = hash.sha256.startChunkedConversion(digestSink);
      final out = zip.openWrite();
      var received = 0;
      try {
        await for (final chunk in res.stream) {
          received += chunk.length;
          if (received > offer.zipSize) {
            throw 'the file is larger than the certificate says';
          }
          hasher.add(chunk);
          out.add(chunk);
          onProgress?.call(received / offer.zipSize);
        }
      } finally {
        await out.close();
      }
      hasher.close();
      if (received != offer.zipSize) {
        throw 'the file is $received bytes, the certificate says ${offer.zipSize}';
      }
      if (digestSink.value.toString() != offer.zipSha256) {
        throw 'the file does not match the certificate';
      }
    } catch (_) {
      if (zip.existsSync()) zip.deleteSync();
      rethrow;
    } finally {
      client.close();
    }

    staged.createSync(recursive: true);
    // tar ships with Windows 10 and 11 and reads zip files. Named by its full
    // path: another `tar` earlier on the PATH (Git's) does not read zips.
    final systemRoot = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    final unpack = await Process.run('$systemRoot\\System32\\tar.exe',
        ['-xf', zip.path, '-C', staged.path]);
    if (unpack.exitCode != 0) {
      throw 'unpacking failed: ${unpack.stderr}';
    }
    zip.deleteSync();

    final source = _folderWithExe(staged);
    if (source == null) throw 'the zip holds no $exeName';
    return source;
  }

  /// Hands over to a small script and closes the app. The script waits for
  /// this process to end, keeps a copy of the database, copies the new files
  /// over the app folder and starts the app again.
  static Future<Never> applyAndRestart(UpdateOffer offer, String source) async {
    final dir = await _updateDir();
    final support = await getApplicationSupportDirectory();
    final script = File('${dir.path}\\apply_update.cmd');
    script.writeAsStringSync(helperScript(
      pid: pid,
      build: offer.build,
      source: source,
      appDir: _appDir(),
      staged: '${dir.path}\\staged',
      database: '${support.path}\\publicos.sqlite',
      log: '${dir.path}\\update.log',
    ));
    await launchHidden(script.path);
    exit(0);
  }

  /// Starts the hand-over script with a hidden console of its own.
  ///
  /// Started detached, `cmd` has no console, so every console program the
  /// script runs (`tasklist`, `find`, `ping`, once a second while it waits)
  /// opened a window of its own: windows that kept reappearing while
  /// the update waited. `Start-Process -WindowStyle Hidden` gives `cmd`
  /// one hidden console that its children share. If PowerShell cannot do it,
  /// the old detached start is the fallback: an update with windows is better
  /// than no update.
  @visibleForTesting
  static Future<void> launchHidden(String scriptPath) async {
    try {
      final quoted = scriptPath.replaceAll("'", "''");
      final r = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-WindowStyle',
        'Hidden',
        '-Command',
        "Start-Process -FilePath cmd.exe -ArgumentList '/c','\"$quoted\"' -WindowStyle Hidden",
      ]).timeout(const Duration(seconds: 15));
      if (r.exitCode == 0) return;
    } catch (_) {}
    await Process.start(
      'cmd.exe',
      ['/c', scriptPath],
      mode: ProcessStartMode.detached,
    );
  }

  /// The hand-over script. `robocopy /E`, never `/MIR`: someone may have
  /// unzipped the app next to their own files. robocopy answers below 8 on
  /// success. `ping` is the wait: `timeout` refuses to run without a console.
  /// The wait for the old app is bounded: after [waitSeconds] checks (one to
  /// two seconds each) the script ends
  /// that process itself, so an app that did not exit cannot hold the update
  /// forever.
  static const waitSeconds = 30;

  @visibleForTesting
  static String helperScript({
    required int pid,
    required int build,
    required String source,
    required String appDir,
    required String staged,
    required String database,
    required String log,
  }) {
    return [
      '@echo off',
      'setlocal',
      'set "LOG=$log"',
      'echo ==== %DATE% %TIME% update to build $build >> "%LOG%"',
      'set /a WAITED=0',
      ':wait',
      'tasklist /FI "PID eq $pid" /FO CSV /NH 2>nul | find /I "$exeName" >nul',
      'if errorlevel 1 goto gone',
      'if %WAITED% GEQ $waitSeconds (',
      '  echo the old app did not exit after $waitSeconds checks, ending it >> "%LOG%"',
      '  taskkill /F /PID $pid >> "%LOG%" 2>&1',
      '  ping -n 2 127.0.0.1 >nul',
      '  goto gone',
      ')',
      'ping -n 2 127.0.0.1 >nul',
      'set /a WAITED+=1',
      'goto wait',
      ':gone',
      'if exist "$database" copy /Y "$database" "$database.before-update" >> "%LOG%" 2>&1',
      'robocopy "$source" "$appDir" /E /R:10 /W:1 /NFL /NDL /NJH /NP >> "%LOG%" 2>&1',
      'if errorlevel 8 (',
      '  echo COPY FAILED, robocopy answered %ERRORLEVEL% >> "%LOG%"',
      ') else (',
      '  echo files copied >> "%LOG%"',
      ')',
      'start "" "$appDir\\$exeName"',
      'rmdir /S /Q "$staged" >> "%LOG%" 2>&1',
      'echo done >> "%LOG%"',
      '',
    ].join('\r\n');
  }

  static String _appDir() => File(Platform.resolvedExecutable).parent.path;

  static Future<Directory> _updateDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}\\update');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// The zip holds the app either at its root or inside one folder.
  static String? _folderWithExe(Directory staged) {
    if (File('${staged.path}\\$exeName').existsSync()) return staged.path;
    for (final entry in staged.listSync()) {
      if (entry is Directory &&
          File('${entry.path}\\$exeName').existsSync()) {
        return entry.path;
      }
    }
    return null;
  }
}

class _DigestSink implements Sink<hash.Digest> {
  late hash.Digest value;
  @override
  void add(hash.Digest data) => value = data;
  @override
  void close() {}
}
