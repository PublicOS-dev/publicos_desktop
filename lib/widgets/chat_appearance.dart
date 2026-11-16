import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

/// **DESKTOP-ONLY — per-side chat appearance overrides.**
///
/// Layered over the client's identity-tint bubble system: the bubble
/// paints the SENDER's on-chain `color` record at full opacity — identity
/// tint is a feature, each peer chose their color. These settings are LOCAL
/// OVERRIDES layered on top, per side (own vs peer): **unset (null) = the
/// client's behavior** — identity tint, auto black/white foreground at the
/// 0.179 luminance crossover, default text metrics. Set = my override on my
/// screen only.
///
/// One instance, loaded at shell boot; `message_widget` reads it through the
/// `_bubbleFill`/`_bubbleFg`/text-style seam (one place, un-driftable) and
/// `chat_screen` listens to rebuild its cached bubbles live while the
/// settings dialog floats over the pane.
///
/// Persisted via PublicOSSettings (`chat_*` keys, the contacts-width record
/// shape). Defensive parse: junk values read as null (= default).
class ChatAppearance extends ChangeNotifier {
  static final ChatAppearance instance = ChatAppearance._();
  ChatAppearance._();

  static const _sides = ['own', 'peer'];

  final Map<String, Color?> _bubbleColor = {};
  final Map<String, Color?> _textColor = {};
  final Map<String, double?> _textSize = {};
  final Map<String, String?> _fontFamily = {};
  final Map<String, FontWeight?> _fontWeight = {};

  String _side(bool isMe) => isMe ? 'own' : 'peer';

  Color? bubbleColorFor(bool isMe) => _bubbleColor[_side(isMe)];
  Color? textColorFor(bool isMe) => _textColor[_side(isMe)];
  double? textSizeFor(bool isMe) => _textSize[_side(isMe)];
  String? fontFamilyFor(bool isMe) => _fontFamily[_side(isMe)];
  FontWeight? fontWeightFor(bool isMe) => _fontWeight[_side(isMe)];

  /// Load every override once (shell boot / dialog open). Absent or
  /// unparsable records land as null = client default.
  Future<void> load() async {
    for (final side in _sides) {
      _bubbleColor[side] = _parseColor(await _read('chat_${side}_bubble_color'));
      _textColor[side] = _parseColor(await _read('chat_${side}_text_color'));
      _textSize[side] = double.tryParse(await _read('chat_${side}_text_size') ?? '');
      final family = await _read('chat_${side}_font_family');
      _fontFamily[side] = (family == null || family.isEmpty) ? null : family;
      _fontWeight[side] = _parseWeight(await _read('chat_${side}_font_weight'));
    }
    notifyListeners();
  }

  Future<void> setBubbleColor(bool isMe, Color? v) async {
    _bubbleColor[_side(isMe)] = v;
    await _write('chat_${_side(isMe)}_bubble_color',
        v == null ? null : v.toARGB32().toString());
    notifyListeners();
  }

  Future<void> setTextColor(bool isMe, Color? v) async {
    _textColor[_side(isMe)] = v;
    await _write('chat_${_side(isMe)}_text_color',
        v == null ? null : v.toARGB32().toString());
    notifyListeners();
  }

  Future<void> setTextSize(bool isMe, double? v) async {
    _textSize[_side(isMe)] = v;
    await _write('chat_${_side(isMe)}_text_size', v?.toString());
    notifyListeners();
  }

  Future<void> setFontFamily(bool isMe, String? v) async {
    _fontFamily[_side(isMe)] = v;
    await _write('chat_${_side(isMe)}_font_family', v);
    notifyListeners();
  }

  Future<void> setFontWeight(bool isMe, FontWeight? v) async {
    _fontWeight[_side(isMe)] = v;
    await _write('chat_${_side(isMe)}_font_weight',
        v == null ? null : (v.index * 100 + 100).toString());
    notifyListeners();
  }

  static Color? _parseColor(String? raw) {
    final n = int.tryParse(raw ?? '');
    return n == null ? null : Color(n);
  }

  static FontWeight? _parseWeight(String? raw) {
    final n = int.tryParse(raw ?? '');
    if (n == null) return null;
    final idx = (n ~/ 100) - 1;
    if (idx < 0 || idx >= FontWeight.values.length) return null;
    return FontWeight.values[idx];
  }

  Future<String?> _read(String key) async {
    try {
      return (await PublicOSSettings.getSetting(key))?.value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      final record = Record.asSettings(
        key: key,
        // Empty string = cleared; _read's parsers treat it as null/default.
        value: value ?? '',
        isExpired: false,
        isSystem: true,
      );
      await PublicOSSettings.setSetting(key, record);
    } catch (_) {}
  }
}
