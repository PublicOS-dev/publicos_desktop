import 'dart:ui' as ui;

/// **PLATFORM STUB — not a deferred feature.**
///
/// The real file is publicos_client's `components/feeds/translation_service.dart`
/// (292 LOC), built on **Google ML Kit** (`google_mlkit_language_id` +
/// `google_mlkit_translation`) — on-device translation of a post into the
/// device language.
///
/// ML Kit is an **Android/iOS-only** SDK. There is no Windows implementation and
/// there will not be one, so this is not waiting on a port — it is waiting on
/// a *different engine* (a cloud translate call, or nothing at all). That is a
/// product decision, not a port.
///
/// The client already anticipated this. Its own [isSupported] is
/// `Platform.isAndroid || Platform.isIOS`, and its doc comment says: *"gate the
/// call site with isSupported; on web/desktop the affordance must not appear."*
/// `post_card` honours that gate before every use. So with `isSupported => false`
/// the translate affordance **correctly hides itself on Windows** — this stub
/// reproduces the client's own designed desktop behavior, and `post_card` needs
/// no edit. The methods below exist only to satisfy the compiler; none are
/// reachable while [isSupported] is false.

/// Language display names. Verbatim from the client — pure data, no ML Kit, and
/// `post_card` reads it for the "Translated from `<Language>`" legend, so it must
/// be real even though translation itself is unsupported here.
const kPostLangNames = <String, String>{
  'af': 'Afrikaans', 'ar': 'Arabic', 'be': 'Belarusian', 'bg': 'Bulgarian',
  'bn': 'Bengali', 'ca': 'Catalan', 'cs': 'Czech', 'cy': 'Welsh',
  'da': 'Danish', 'de': 'German', 'el': 'Greek', 'en': 'English',
  'eo': 'Esperanto', 'es': 'Spanish', 'et': 'Estonian', 'fa': 'Persian',
  'fi': 'Finnish', 'fr': 'French', 'ga': 'Irish', 'gl': 'Galician',
  'gu': 'Gujarati', 'he': 'Hebrew', 'hi': 'Hindi', 'hr': 'Croatian',
  'ht': 'Haitian', 'hu': 'Hungarian', 'id': 'Indonesian', 'is': 'Icelandic',
  'it': 'Italian', 'ja': 'Japanese', 'ka': 'Georgian', 'kn': 'Kannada',
  'ko': 'Korean', 'lt': 'Lithuanian', 'lv': 'Latvian', 'mk': 'Macedonian',
  'mr': 'Marathi', 'ms': 'Malay', 'mt': 'Maltese', 'nl': 'Dutch',
  'no': 'Norwegian', 'pl': 'Polish', 'pt': 'Portuguese', 'ro': 'Romanian',
  'ru': 'Russian', 'sk': 'Slovak', 'sl': 'Slovenian', 'sq': 'Albanian',
  'sv': 'Swedish', 'sw': 'Swahili', 'ta': 'Tamil', 'te': 'Telugu',
  'th': 'Thai', 'tl': 'Tagalog', 'tr': 'Turkish', 'uk': 'Ukrainian',
  'ur': 'Urdu', 'vi': 'Vietnamese', 'zh': 'Chinese',
};

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  /// **The load-bearing line.** ML Kit has no Windows backend, so the client's
  /// own gate hides every translate affordance on desktop.
  static bool get isSupported => false;

  /// Device UI language as a BCP-47 base code. Verbatim from the client (pure
  /// Flutter, no ML Kit) — safe to keep real.
  String get deviceLanguage =>
      ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();

  Future<String?> detect(String text) async => null;

  Future<bool> isModelReady(String from, String to) async => false;

  Future<void> ensureModel(String from, String to,
      {bool requireWifi = false}) async {
    throw UnsupportedError('Translation is not available on Windows.');
  }

  Future<String> translate(String text,
      {required String from,
      required String to,
      bool requireWifi = false}) async {
    throw UnsupportedError('Translation is not available on Windows.');
  }

  bool supportsPair(String from, String to) => false;

  Future<void> dispose() async {}
}

/// Prefs half of the client's file. Unreachable on desktop (every caller sits
/// behind `TranslationService.isSupported`), present so `post_card` compiles
/// verbatim. Values are the client's defaults.
class TranslationPrefs {
  static Future<bool> isEnabled() async => false;
  static Future<void> setEnabled(bool value) async {}
  static Future<bool> wifiOnly() async => false;
  static Future<void> setWifiOnly(bool value) async {}
  static Future<Set<String>> disabledSources() async => <String>{};
  static Future<bool> isSourceSuggested(String code) async => true;
  static Future<void> setSourceSuggested(String code, bool suggested) async {}
  static Future<void> reset() async {}
}
