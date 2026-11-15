import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:publicos_core/publicos_core.dart';

/// Singleton that generates a short bell chime in memory and plays it
/// for incoming messages. Togglable via [enabled] / [setEnabled].
///
/// The chime plays on ALL incoming messages; the toggle is in the
/// Chat-settings dialog. The preference lives in PublicOSSettings
/// (`chat_chime_enabled`), the desktop's settings store. The bell itself is
/// synthesized — C6 + G6 + C7 with exponential decay — so no audio asset
/// exists or is needed.
class NotificationSound {
  static final NotificationSound instance = NotificationSound._();
  NotificationSound._();

  static const _settingKey = 'chat_chime_enabled';

  AudioPlayer? _player;
  String? _chimePath;
  bool _enabled = true;
  DateTime? _lastPlayed;

  bool get enabled => _enabled;

  /// Call once at app start (e.g. in AppShell.initState).
  Future<void> init() async {
    try {
      final record = await PublicOSSettings.getSetting(_settingKey);
      _enabled = record?.value != 'false';
    } catch (_) {}

    // Generate chime WAV and write to temp file once
    final wavBytes = _generateChime();
    final file = File('${Directory.systemTemp.path}/publicos_chime.wav');
    await file.writeAsBytes(wavBytes, flush: true);
    _chimePath = file.path;

    _player = AudioPlayer();
    await _player!.setReleaseMode(ReleaseMode.stop);
    await _player!.setVolume(0.7);
  }

  /// Toggle the chime on/off and persist the preference.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final record = Record.asSettings(
      key: _settingKey,
      value: value.toString(),
      expiration: DateTime.now().add(const Duration(days: 365)),
      isExpired: false,
      isSystem: true,
    );
    await PublicOSSettings.setSetting(_settingKey, record);
  }

  /// Play the chime if enabled. Rate-limited to once per 2 seconds.
  Future<void> play() async {
    if (!_enabled || _chimePath == null || _player == null) return;

    final now = DateTime.now();
    if (_lastPlayed != null &&
        now.difference(_lastPlayed!).inMilliseconds < 2000) {
      return;
    }
    _lastPlayed = now;

    try {
      await _player!.play(DeviceFileSource(_chimePath!));
    } catch (_) {}
  }

  /// Play unconditionally — no rate limit, ignores enabled state. (The
  /// settings dialog uses this to preview the bell.)
  Future<void> playForced() async {
    if (_chimePath == null || _player == null) return;
    try {
      await _player!.play(DeviceFileSource(_chimePath!));
    } catch (_) {}
  }

  /// Generate a pleasant short bell chime as a WAV byte array.
  ///
  /// C6 (1046.5 Hz) + G6 (1568 Hz) + C7 (2093 Hz) — a bright perfect fifth
  /// with octave harmonic, exponential decay over 250 ms.
  Uint8List _generateChime() {
    const sampleRate = 44100;
    const durationMs = 250;
    const numSamples = sampleRate * durationMs ~/ 1000;

    final samples = Int16List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final progress = i / numSamples;
      final decay = exp(-progress * 5.0);
      final sample = (sin(2 * pi * 1046.5 * t) * 0.45 +
              sin(2 * pi * 1568.0 * t) * 0.25 +
              sin(2 * pi * 2093.0 * t) * 0.15) *
          decay;
      samples[i] = (sample * 32767 * 0.5).round().clamp(-32768, 32767);
    }

    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    // RIFF header
    _writeAscii(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _writeAscii(buffer, 8, 'WAVE');

    // fmt chunk
    _writeAscii(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little); // PCM
    buffer.setUint16(22, 1, Endian.little); // mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32, 2, Endian.little); // block align
    buffer.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    _writeAscii(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      buffer.setInt16(44 + i * 2, samples[i], Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  void _writeAscii(ByteData buffer, int offset, String str) {
    for (int i = 0; i < str.length; i++) {
      buffer.setUint8(offset + i, str.codeUnitAt(i));
    }
  }

  void dispose() {
    _player?.dispose();
  }
}
